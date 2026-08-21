import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/combo_trainer.dart';
import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../core/models.dart';
import '../core/timer_session_engine.dart';
import '../services/history_repository.dart';
import '../services/sound_manager.dart';
import '../services/user_settings.dart';

/// Port of the iOS `FightTimerViewModel` (ViewModels.swift) including its
/// fixes: start/resume finished-state guards, idle skip guard, realtime
/// 10s-warning guard and the warmup==0 opening bell.
class FightTimerController extends ChangeNotifier {
  FightTimerController(FightPreset preset)
      : currentPreset = preset,
        _engine = TimerSessionEngine.fight(preset) {
    final TimerSessionSnapshot s = _engine.snapshot(DateTime.now());
    phase = s.phase;
    timeRemaining = s.timeRemaining;
    currentRound = s.currentStep;
    _lastSnapshot = s;
  }

  FightPreset currentPreset;
  TimerPhase phase = TimerPhase.warmup;
  TimerStatus status = TimerStatus.idle;
  int timeRemaining = 0;
  int currentRound = 0;
  bool hasSavedCurrentWorkout = false;
  String? saveErrorMessage;

  UserSettings? settings;
  VoidCallback? onWorkoutSaved;

  TimerSessionEngine _engine;
  Timer? _ticker;
  TimerSessionSnapshot? _lastSnapshot;
  int? _warnedSegmentIndex;
  DateTime? _workoutStartTime;
  int _totalElapsedSeconds = 0;
  int? _savedWorkoutId;
  final SoundManager _sound = SoundManager.instance;

  // Combo Trainer: announces random punch combos during rounds. Timing is
  // driven off the running ticker via real elapsed time, so it survives
  // pause/resume and never fires on a skip (which advances no wall-clock time).
  final ComboTrainer _comboTrainer = ComboTrainer();
  DateTime? _lastComboTime;
  int _nextComboDelay = 0;

  bool get _soundOn => settings?.soundEnabled ?? true;
  bool get _vibrationOn => settings?.vibrationEnabled ?? true;
  bool get _warningOn => settings?.warningEnabled ?? true;
  bool get _comboOn => settings?.comboTrainerEnabled ?? false;
  bool get _comboUseNames => settings?.comboUseNames ?? false;

  double get progress => _lastSnapshot?.progress ?? 0;

  /// Background color follows the PHASE (round=green, rest=red) and is
  /// preserved while paused — see redesign prefs.
  Color get backgroundColor => DS.phaseColor(phase);

  String get timeString {
    final int m = timeRemaining ~/ 60;
    final int s = timeRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String phaseText(Translations t) {
    switch (phase) {
      case TimerPhase.warmup:
        return t.phaseWarmUp;
      case TimerPhase.round:
        return '${t.phaseRound} $currentRound/${currentPreset.rounds}';
      case TimerPhase.rest:
        return t.phaseRest;
      case TimerPhase.cooldown:
        return t.phaseCoolDown;
      case TimerPhase.finished:
        return t.phaseFinished;
    }
  }

  void start() {
    final DateTime now = DateTime.now();
    if (status == TimerStatus.paused && phase != TimerPhase.finished) {
      resume();
      return;
    }
    _prepareNewSession(now);
    _engine.start(now);
    status = TimerStatus.running;
    WakelockPlus.enable();
    _startTicker();
    _apply(_engine.snapshot(now), now, allowEffects: false);
    // Warm-up == 0: erster Abschnitt ist direkt Runde 1 — Eröffnungsglocke
    // + Ansage nachholen (das Start-Snapshot läuft ohne Effekte).
    if (phase == TimerPhase.round) {
      _sound.play(SoundType.roundStart, soundEnabled: _soundOn);
      _sound.haptic(SoundType.roundStart, vibrationEnabled: _vibrationOn);
      _sound.speakRound(
        _lastSnapshot?.currentStep ?? 1,
        soundEnabled: _soundOn,
      );
    }
    notifyListeners();
  }

  void pause() {
    if (status != TimerStatus.running) return;
    final DateTime now = DateTime.now();
    _engine.pause(now);
    status = TimerStatus.paused;
    _stopTicker();
    WakelockPlus.disable();
    // Drop the combo clock; it re-initializes on the next running tick so a
    // long pause doesn't trigger a burst of combos on resume.
    _lastComboTime = null;
    _apply(_engine.snapshot(now), now, allowEffects: false);
    notifyListeners();
  }

  void resume() {
    if (phase == TimerPhase.finished) {
      start();
      return;
    }
    if (status != TimerStatus.paused) return;
    final DateTime now = DateTime.now();
    _engine.start(now);
    status = TimerStatus.running;
    WakelockPlus.enable();
    _startTicker();
    _apply(_engine.snapshot(now), now, allowEffects: false);
    notifyListeners();
  }

  void reset() {
    _stopTicker();
    status = TimerStatus.idle;
    WakelockPlus.disable();
    _engine = TimerSessionEngine.fight(currentPreset);
    _engine.reset();
    _workoutStartTime = null;
    _totalElapsedSeconds = 0;
    _warnedSegmentIndex = null;
    _savedWorkoutId = null;
    _lastComboTime = null;
    hasSavedCurrentWorkout = false;
    saveErrorMessage = null;
    final DateTime now = DateTime.now();
    _apply(_engine.snapshot(now), now, allowEffects: false);
    notifyListeners();
  }

  void skip() {
    if (status == TimerStatus.idle) return;
    final DateTime now = DateTime.now();
    final TimerSessionSnapshot previous =
        _lastSnapshot ?? _engine.snapshot(now);
    _engine.skip(now);
    _apply(
      _engine.snapshot(now),
      now,
      allowEffects: true,
      previousSnapshot: previous,
    );
    notifyListeners();
  }

  /// Nach Rückkehr aus dem Hintergrund den Stand von der Wanduhr neu ableiten.
  void refreshFromClock() {
    if (status != TimerStatus.running) return;
    final DateTime now = DateTime.now();
    _apply(_engine.snapshot(now), now, allowEffects: true);
    notifyListeners();
  }

  void updatePreset(FightPreset preset) {
    currentPreset = preset;
    reset();
  }

  Future<bool> saveWorkoutToHistory({bool allowUpdate = false}) async {
    final DateTime? start = _workoutStartTime;
    if (start == null || _totalElapsedSeconds <= 0) return false;
    if (hasSavedCurrentWorkout && !allowUpdate) return false;

    final WorkoutRecord record = WorkoutRecord(
      id: _savedWorkoutId,
      date: start,
      mode: modeFightTimer,
      sportName: currentPreset.name,
      totalDuration: _totalElapsedSeconds,
      rounds: currentPreset.rounds,
      roundSeconds: currentPreset.roundSeconds,
      restSeconds: currentPreset.restSeconds,
      warmupSeconds: currentPreset.warmupSeconds,
    );
    try {
      final bool isFirstSave = _savedWorkoutId == null;
      if (isFirstSave) {
        _savedWorkoutId = await HistoryRepository.instance.insert(record);
      } else {
        await HistoryRepository.instance.update(record);
      }
      // completeWorkout() calls this without awaiting it, so the screen
      // (and this controller) may already be disposed by the time the
      // save resolves — never touch state or notify after that.
      if (_disposed) return true;
      hasSavedCurrentWorkout = true;
      saveErrorMessage = null;
      if (isFirstSave) onWorkoutSaved?.call();
      notifyListeners();
      return true;
    } catch (e) {
      if (_disposed) return false;
      saveErrorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // MARK: - internals

  void _prepareNewSession(DateTime now) {
    _stopTicker();
    _engine = TimerSessionEngine.fight(currentPreset);
    _engine.reset();
    _workoutStartTime = now;
    _totalElapsedSeconds = 0;
    _warnedSegmentIndex = null;
    _savedWorkoutId = null;
    _lastComboTime = null;
    hasSavedCurrentWorkout = false;
    saveErrorMessage = null;
    _lastSnapshot = _engine.snapshot(now);
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final DateTime now = DateTime.now();
      _apply(_engine.snapshot(now), now, allowEffects: true);
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _apply(
    TimerSessionSnapshot snapshot,
    DateTime now, {
    required bool allowEffects,
    TimerSessionSnapshot? previousSnapshot,
  }) {
    final TimerSessionSnapshot? previous = previousSnapshot ?? _lastSnapshot;
    phase = snapshot.phase;
    currentRound = snapshot.currentStep;
    timeRemaining = snapshot.timeRemaining;
    _totalElapsedSeconds = snapshot.elapsedSeconds;

    if (allowEffects) {
      _playTransitionEffects(previous, snapshot);
      _playWarningIfNeeded(previous, snapshot);
      _handleCombo(previous, snapshot, now);
    }

    _lastSnapshot = snapshot;

    if (snapshot.isFinished) {
      _completeWorkout(now);
    }
  }

  void _playTransitionEffects(
    TimerSessionSnapshot? previous,
    TimerSessionSnapshot snapshot,
  ) {
    if (previous == null || previous.segmentIndex == snapshot.segmentIndex) {
      return;
    }
    switch (snapshot.phase) {
      case TimerPhase.round:
        _sound.play(SoundType.roundStart, soundEnabled: _soundOn);
        _sound.haptic(SoundType.roundStart, vibrationEnabled: _vibrationOn);
        _sound.speakRound(
          snapshot.currentStep,
          soundEnabled: _soundOn,
        );
        break;
      case TimerPhase.rest:
      case TimerPhase.cooldown:
        _sound.play(SoundType.roundEnd, soundEnabled: _soundOn);
        _sound.haptic(SoundType.roundEnd, vibrationEnabled: _vibrationOn);
        break;
      case TimerPhase.finished:
        _sound.play(SoundType.workoutEnd, soundEnabled: _soundOn);
        _sound.haptic(SoundType.workoutEnd, vibrationEnabled: _vibrationOn);
        break;
      case TimerPhase.warmup:
        break;
    }
  }

  void _playWarningIfNeeded(
    TimerSessionSnapshot? previous,
    TimerSessionSnapshot snapshot,
  ) {
    if (snapshot.phase != TimerPhase.round || !_warningOn) return;
    if (_warnedSegmentIndex == snapshot.segmentIndex) return;
    if (previous == null || previous.segmentIndex != snapshot.segmentIndex) {
      return;
    }
    if (!(previous.timeRemaining > 10 && snapshot.timeRemaining <= 10)) return;

    // Grenze gilt als behandelt — auch wenn wir gleich nicht abspielen.
    _warnedSegmentIndex = snapshot.segmentIndex;

    // Nur bei Echtzeit-Übergang abspielen; nach großem Sprung (Hintergrund/
    // Skip) käme die Warnung viel zu spät.
    if (previous.timeRemaining - snapshot.timeRemaining > 2) return;

    _sound.play(SoundType.roundWarning, soundEnabled: _soundOn);
    _sound.haptic(SoundType.roundWarning, vibrationEnabled: _vibrationOn);
  }

  /// Announces a random combo during a round at randomized intervals. Only
  /// runs while a round is actually running (called from the ticker with
  /// allowEffects); a skip changes segment but no wall-clock time, so it can't
  /// trigger a combo.
  void _handleCombo(
    TimerSessionSnapshot? previous,
    TimerSessionSnapshot snapshot,
    DateTime now,
  ) {
    if (!_comboOn ||
        snapshot.phase != TimerPhase.round ||
        status != TimerStatus.running) {
      return;
    }
    final bool enteredRound =
        previous == null || previous.segmentIndex != snapshot.segmentIndex;
    // Start (or restart, after a pause) the combo clock without an immediate
    // announcement — the round-start bell/announcement just played.
    if (enteredRound || _lastComboTime == null) {
      _lastComboTime = now;
      _nextComboDelay = _comboTrainer.nextDelaySeconds();
      return;
    }
    if (now.difference(_lastComboTime!).inSeconds < _nextComboDelay) return;

    _sound.speakCombo(
      ComboTrainer.phraseFor(_comboTrainer.nextCombo(), useNames: _comboUseNames),
      soundEnabled: _soundOn,
    );
    _lastComboTime = now;
    _nextComboDelay = _comboTrainer.nextDelaySeconds();
  }

  void _completeWorkout(DateTime now) {
    if (status != TimerStatus.running) return;
    _engine.pause(now);
    status = TimerStatus.paused;
    _stopTicker();
    WakelockPlus.disable();
    // Automatisch speichern (aktualisiert einen früheren manuellen Save).
    saveWorkoutToHistory(allowUpdate: true);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _stopTicker();
    WakelockPlus.disable();
    super.dispose();
  }
}
