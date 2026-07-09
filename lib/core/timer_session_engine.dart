// Wall-clock timer engine — EXACT port of iOS TimerSessionEngine.swift.
//
// Pure Dart (no Flutter imports). The engine never ticks: it derives the
// full timer state from a wall-clock `DateTime`, so it is drift-free and
// survives app backgrounding, exactly like the iOS value type.

import 'package:boxing_timer_flutter/core/models.dart';

/// Immutable view of the timer state at a point in time
/// (iOS `TimerSessionSnapshot`).
class TimerSessionSnapshot {
  final TimerPhase phase;
  final int timeRemaining;
  final int elapsedSeconds;
  final int currentStep;
  final int totalSteps;
  final double progress;
  final int segmentIndex;
  final bool isFinished;

  const TimerSessionSnapshot({
    required this.phase,
    required this.timeRemaining,
    required this.elapsedSeconds,
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
    required this.segmentIndex,
    required this.isFinished,
  });

  @override
  bool operator ==(Object other) =>
      other is TimerSessionSnapshot &&
      other.phase == phase &&
      other.timeRemaining == timeRemaining &&
      other.elapsedSeconds == elapsedSeconds &&
      other.currentStep == currentStep &&
      other.totalSteps == totalSteps &&
      other.progress == progress &&
      other.segmentIndex == segmentIndex &&
      other.isFinished == isFinished;

  @override
  int get hashCode => Object.hash(phase, timeRemaining, elapsedSeconds,
      currentStep, totalSteps, progress, segmentIndex, isFinished);

  @override
  String toString() =>
      'TimerSessionSnapshot(phase: $phase, timeRemaining: $timeRemaining, '
      'elapsedSeconds: $elapsedSeconds, currentStep: $currentStep/'
      '$totalSteps, progress: $progress, segmentIndex: $segmentIndex, '
      'isFinished: $isFinished)';
}

class _TimerSessionSegment {
  final TimerPhase phase;
  final int duration;
  final int currentStep;
  final int totalSteps;

  const _TimerSessionSegment({
    required this.phase,
    required this.duration,
    required this.currentStep,
    required this.totalSteps,
  });
}

/// Segment-list wall-clock engine (iOS `TimerSessionEngine`).
class TimerSessionEngine {
  final List<_TimerSessionSegment> _segments;

  /// Seconds accumulated before the current running stretch
  /// (iOS `elapsedBeforeRun: TimeInterval` — fractional seconds preserved).
  double _elapsedBeforeRun = 0;
  DateTime? _runningStartedAt;

  TimerSessionEngine._(this._segments);

  /// iOS `TimerSessionEngine.fight(preset:)`.
  /// Warmup only if > 0; rest only between rounds; zero-length segments
  /// filtered out.
  factory TimerSessionEngine.fight(FightPreset preset) {
    final segments = <_TimerSessionSegment>[];
    final rounds = preset.rounds < 1 ? 1 : preset.rounds;
    if (preset.warmupSeconds > 0) {
      segments.add(_TimerSessionSegment(
        phase: TimerPhase.warmup,
        duration: preset.warmupSeconds,
        currentStep: 0,
        totalSteps: rounds,
      ));
    }
    for (var round = 1; round <= rounds; round++) {
      segments.add(_TimerSessionSegment(
        phase: TimerPhase.round,
        duration: preset.roundSeconds,
        currentStep: round,
        totalSteps: rounds,
      ));
      if (round < rounds && preset.restSeconds > 0) {
        segments.add(_TimerSessionSegment(
          phase: TimerPhase.rest,
          duration: preset.restSeconds,
          currentStep: round,
          totalSteps: rounds,
        ));
      }
    }
    return TimerSessionEngine._(
        segments.where((s) => s.duration > 0).toList(growable: false));
  }

  /// iOS `TimerSessionEngine.interval(workout:)`.
  /// Warmup only if > 0; rest only between intervals; cooldown only if > 0;
  /// zero-length segments filtered out.
  factory TimerSessionEngine.interval(IntervalWorkout workout) {
    final segments = <_TimerSessionSegment>[];
    final intervals = workout.intervals < 1 ? 1 : workout.intervals;
    if (workout.warmupSeconds > 0) {
      segments.add(_TimerSessionSegment(
        phase: TimerPhase.warmup,
        duration: workout.warmupSeconds,
        currentStep: 0,
        totalSteps: intervals,
      ));
    }
    for (var interval = 1; interval <= intervals; interval++) {
      segments.add(_TimerSessionSegment(
        phase: TimerPhase.round,
        duration: workout.workSeconds,
        currentStep: interval,
        totalSteps: intervals,
      ));
      if (interval < intervals && workout.restSeconds > 0) {
        segments.add(_TimerSessionSegment(
          phase: TimerPhase.rest,
          duration: workout.restSeconds,
          currentStep: interval,
          totalSteps: intervals,
        ));
      }
    }
    if (workout.cooldownSeconds > 0) {
      segments.add(_TimerSessionSegment(
        phase: TimerPhase.cooldown,
        duration: workout.cooldownSeconds,
        currentStep: intervals,
        totalSteps: intervals,
      ));
    }
    return TimerSessionEngine._(
        segments.where((s) => s.duration > 0).toList(growable: false));
  }

  bool get isRunning => _runningStartedAt != null;

  int get totalDuration =>
      _segments.fold(0, (sum, segment) => sum + segment.duration);

  /// Starts (or resumes) the clock. No-op if already running.
  void start(DateTime at) {
    if (_runningStartedAt != null) return;
    _runningStartedAt = at;
  }

  /// Freezes the accumulated elapsed time and stops the clock.
  void pause(DateTime at) {
    _elapsedBeforeRun = _elapsed(at);
    _runningStartedAt = null;
  }

  void reset() {
    _elapsedBeforeRun = 0;
    _runningStartedAt = null;
  }

  /// Jumps to the end of the current segment. If running, the wall-clock
  /// anchor is re-based to `at` so time continues from the boundary.
  void skip(DateTime at) {
    final current = snapshot(at);
    _elapsedBeforeRun = _segmentEndElapsed(current.segmentIndex).toDouble();
    if (_runningStartedAt != null) {
      _runningStartedAt = at;
    }
  }

  TimerSessionSnapshot snapshot(DateTime at) {
    var clampedElapsed = _elapsed(at);
    if (clampedElapsed < 0) clampedElapsed = 0;
    final total = totalDuration;
    if (clampedElapsed > total) clampedElapsed = total.toDouble();
    final elapsedSeconds = clampedElapsed.floor();

    if (_segments.isEmpty || elapsedSeconds >= total) {
      return _finishedSnapshot();
    }

    var segmentStart = 0;
    for (var index = 0; index < _segments.length; index++) {
      final segment = _segments[index];
      final segmentEnd = segmentStart + segment.duration;
      if (elapsedSeconds < segmentEnd) {
        final elapsedInSegment = elapsedSeconds - segmentStart;
        var remaining = segment.duration - elapsedInSegment;
        if (remaining < 0) remaining = 0;
        final progress = segment.duration > 0
            ? elapsedInSegment / segment.duration
            : 1.0;
        return TimerSessionSnapshot(
          phase: segment.phase,
          timeRemaining: remaining,
          elapsedSeconds: elapsedSeconds,
          currentStep: segment.currentStep,
          totalSteps: segment.totalSteps,
          progress: progress,
          segmentIndex: index,
          isFinished: false,
        );
      }
      segmentStart = segmentEnd;
    }

    return _finishedSnapshot();
  }

  TimerSessionSnapshot _finishedSnapshot() {
    final lastTotalSteps = _segments.isEmpty ? 0 : _segments.last.totalSteps;
    return TimerSessionSnapshot(
      phase: TimerPhase.finished,
      timeRemaining: 0,
      elapsedSeconds: totalDuration,
      currentStep: lastTotalSteps,
      totalSteps: lastTotalSteps,
      progress: 1,
      segmentIndex: _segments.length,
      isFinished: true,
    );
  }

  double _elapsed(DateTime at) {
    final startedAt = _runningStartedAt;
    if (startedAt == null) return _elapsedBeforeRun;
    final running =
        at.difference(startedAt).inMicroseconds / Duration.microsecondsPerSecond;
    return _elapsedBeforeRun + (running > 0 ? running : 0);
  }

  int _segmentEndElapsed(int segmentIndex) {
    if (segmentIndex >= _segments.length) return totalDuration;
    var sum = 0;
    for (var i = 0; i <= segmentIndex; i++) {
      sum += _segments[i].duration;
    }
    return sum;
  }
}
