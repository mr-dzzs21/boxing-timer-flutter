import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/fight_timer_controller.dart';
import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../core/models.dart';
import '../services/profile_manager.dart';
import '../services/prompt_manager.dart';
import '../services/user_settings.dart';
import 'settings_screen.dart';

/// Port of the iOS `FightTimerView` — Bold/Athletic look, phase-colored
/// full-bleed background, big dial, white controls.
class FightTimerScreen extends StatefulWidget {
  const FightTimerScreen({super.key});

  @override
  State<FightTimerScreen> createState() => _FightTimerScreenState();
}

class _FightTimerScreenState extends State<FightTimerScreen>
    with WidgetsBindingObserver {
  late final FightTimerController _c;

  @override
  void initState() {
    super.initState();
    _c = FightTimerController(FightPreset.defaultPresets.first);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _c.settings = context.read<UserSettings>();
      _c.onWorkoutSaved =
          () => context.read<PromptManager>().recordWorkoutCompleted();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _c.refreshFromClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LanguageManager lang = context.watch<LanguageManager>();
    final Translations t = lang.t;
    _c.ttsLanguageCode = lang.current.code;

    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) {
        return AthleticBackground(
          color: _c.backgroundColor,
          child: SafeArea(
            child: Column(
              children: <Widget>[
                _topBar(lang, t),
                Expanded(
                  child: OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                      return orientation == Orientation.landscape
                          ? _landscape(t)
                          : _portrait(t);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(LanguageManager lang, Translations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showPresetPicker,
            child: DSChip(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    lang.localizedPresetName(_c.currentPreset.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _showProfileEditor,
            icon: const Icon(Icons.add_circle, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _portrait(Translations t) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double ring =
            math.min(math.min(c.maxWidth * 0.82, c.maxHeight * 0.55), 330);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: <Widget>[
              const Spacer(),
              DSTimerDial(
                phaseText: _c.phaseText(t),
                timeString: _c.timeString,
                progress: _c.progress,
                diameter: ring,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DSCircleButton(icon: Icons.refresh, onPressed: _c.reset),
                  const SizedBox(width: 28),
                  DSPlayPauseButton(
                    isRunning: _c.status == TimerStatus.running,
                    onPressed: _playPauseTapped,
                  ),
                  const SizedBox(width: 28),
                  DSCircleButton(icon: Icons.fast_forward, onPressed: _c.skip),
                ],
              ),
              const SizedBox(height: 12),
              _saveButton(t),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _landscape(Translations t) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _c.phaseText(t).toUpperCase(),
                style: DS.display(20).copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 2,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _c.timeString,
                  style: DS.timer(140).copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DSCircleButton(icon: Icons.refresh, onPressed: _c.reset),
              const SizedBox(height: 20),
              DSPlayPauseButton(
                isRunning: _c.status == TimerStatus.running,
                onPressed: _playPauseTapped,
              ),
              const SizedBox(height: 20),
              DSCircleButton(icon: Icons.fast_forward, onPressed: _c.skip),
            ],
          ),
        ),
      ],
    );
  }

  Widget _saveButton(Translations t) {
    final bool visible = _c.status == TimerStatus.paused;
    return Opacity(
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: DSPrimaryButton(
          label: _c.hasSavedCurrentWorkout ? t.saved : t.saveWorkout,
          onPressed: _c.hasSavedCurrentWorkout ? null : _saveTapped,
        ),
      ),
    );
  }

  void _playPauseTapped() {
    if (_c.status == TimerStatus.running) {
      _c.pause();
    } else if (_c.status == TimerStatus.idle) {
      _c.start();
    } else {
      _c.resume();
    }
  }

  Future<void> _saveTapped() async {
    final Translations t = context.read<LanguageManager>().t;
    final bool ok = await _c.saveWorkoutToHistory();
    if (!mounted) return;
    if (ok) {
      _showInfoDialog(t.saved, null, t.ok);
    } else if (_c.saveErrorMessage != null) {
      _showInfoDialog(t.saveError, _c.saveErrorMessage, t.ok);
    }
  }

  void _showInfoDialog(String title, String? message, String ok) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: DS.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: message == null
            ? null
            : Text(message, style: const TextStyle(color: DS.textSecondary)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ok, style: const TextStyle(color: DS.accent)),
          ),
        ],
      ),
    );
  }

  void _showPresetPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DS.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Consumer2<LanguageManager, ProfileManager>(
          builder: (BuildContext context, LanguageManager lang,
              ProfileManager pm, _) {
            final Translations t = lang.t;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    _sheetHeader(t.standardPresets),
                    for (final FightPreset p in FightPreset.defaultPresets)
                      _presetRow(
                        lang.localizedPresetName(p.name),
                        selected: _c.currentPreset.id == p.id,
                        onTap: () {
                          _c.updatePreset(p);
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                    if (pm.customProfiles.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      _sheetHeader(t.customProfiles),
                      for (final FightPreset p in pm.customProfiles)
                        _presetRow(
                          p.name,
                          selected: _c.currentPreset.id == p.id,
                          onTap: () {
                            _c.updatePreset(p);
                            Navigator.of(sheetContext).pop();
                          },
                          onDelete: () => pm.remove(p.id),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sheetHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: DS.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _presetRow(
    String title, {
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (selected)
              const Icon(Icons.check, color: DS.accent, size: 20),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    color: DS.phaseRest, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  void _showProfileEditor() {
    final Translations t = context.read<LanguageManager>().t;
    final TextEditingController nameController = TextEditingController();
    int rounds = 3;
    int roundSeconds = 180;
    int restSeconds = 60;
    int warmupSeconds = 10;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DS.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(t.newProfile,
                      style: DS.display(22).copyWith(color: Colors.white)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: DS.accent,
                    decoration: InputDecoration(
                      hintText: t.profileNameHint,
                      hintStyle: const TextStyle(color: DS.textTertiary),
                      filled: true,
                      fillColor: DS.surfaceHi,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DSStepperRow(
                    label: t.rounds,
                    value: rounds,
                    unit: 'x',
                    min: 1,
                    max: 20,
                    step: 1,
                    onChanged: (int v) => setSheetState(() => rounds = v),
                  ),
                  DSStepperRow(
                    label: t.roundTime,
                    value: roundSeconds,
                    unit: 's',
                    min: 10,
                    max: 900,
                    step: 10,
                    onChanged: (int v) =>
                        setSheetState(() => roundSeconds = v),
                  ),
                  DSStepperRow(
                    label: t.rest,
                    value: restSeconds,
                    unit: 's',
                    min: 0,
                    max: 600,
                    step: 5,
                    onChanged: (int v) => setSheetState(() => restSeconds = v),
                  ),
                  DSStepperRow(
                    label: t.warmUp,
                    value: warmupSeconds,
                    unit: 's',
                    min: 0,
                    max: 600,
                    step: 5,
                    onChanged: (int v) =>
                        setSheetState(() => warmupSeconds = v),
                  ),
                  const SizedBox(height: 16),
                  DSPrimaryButton(
                    label: t.save,
                    onPressed: () {
                      final String name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final FightPreset preset = FightPreset(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        name: name,
                        rounds: rounds,
                        roundSeconds: roundSeconds,
                        restSeconds: restSeconds,
                        warmupSeconds: warmupSeconds,
                        isCustom: true,
                      );
                      context.read<ProfileManager>().add(preset);
                      _c.updatePreset(preset);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
