import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/interval_timer_controller.dart';
import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../core/models.dart';
import '../services/prompt_manager.dart';
import '../services/user_settings.dart';

/// Port of the iOS `IntervalTimerView` — config (preset/custom) + timer.
class IntervalTimerScreen extends StatefulWidget {
  const IntervalTimerScreen({super.key});

  @override
  State<IntervalTimerScreen> createState() => _IntervalTimerScreenState();
}

class _IntervalTimerScreenState extends State<IntervalTimerScreen>
    with WidgetsBindingObserver {
  late final IntervalTimerController _c;

  bool _showConfig = true;
  bool _useCustom = false;
  IntervalDevice _device = IntervalDevice.running;
  IntervalLevel _level = IntervalLevel.beginner;
  int _customWarmup = 60;
  int _customIntervals = 8;
  int _customWork = 30;
  int _customRest = 30;

  @override
  void initState() {
    super.initState();
    _c = IntervalTimerController(
      IntervalWorkout.workoutFor(IntervalDevice.running, IntervalLevel.beginner),
    );
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
            child: _showConfig ? _configView(t) : _timerView(t),
          ),
        );
      },
    );
  }

  // MARK: - Config

  Widget _configView(Translations t) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                t.chooseTraining.toUpperCase(),
                style: DS.display(26).copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              DSSegmentedPicker<bool>(
                value: _useCustom,
                options: <(bool, String)>[
                  (false, t.preset),
                  (true, t.customSetting),
                ],
                onChanged: (bool v) => setState(() => _useCustom = v),
              ),
              const SizedBox(height: 16),
              if (_useCustom) ..._customConfig(t) else ..._presetConfig(t),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: DSPrimaryButton(
            label: t.startTraining,
            onPressed: () {
              final IntervalWorkout w = _useCustom
                  ? IntervalWorkout(
                      device: IntervalDevice.bagWork,
                      level: IntervalLevel.intermediate,
                      warmupSeconds: _customWarmup,
                      intervals: _customIntervals,
                      workSeconds: _customWork,
                      restSeconds: _customRest,
                      cooldownSeconds: 0,
                    )
                  : IntervalWorkout.workoutFor(_device, _level);
              _c.updateWorkout(w);
              setState(() => _showConfig = false);
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _presetConfig(Translations t) {
    final IntervalWorkout w = IntervalWorkout.workoutFor(_device, _level);
    return <Widget>[
      DSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(t.device, style: DS.headline().copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: <Widget>[
                for (final IntervalDevice d in IntervalDevice.values)
                  DSSelectableCard(
                    title: deviceLabel(d, t),
                    isSelected: _device == d,
                    onTap: () => setState(() => _device = d),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      DSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(t.level, style: DS.headline().copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                for (final IntervalLevel l in IntervalLevel.values) ...<Widget>[
                  if (l != IntervalLevel.values.first)
                    const SizedBox(width: 8),
                  Expanded(
                    child: DSSelectableCard(
                      title: levelLabel(l, t),
                      isSelected: _level == l,
                      onTap: () => setState(() => _level = l),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _breakdownCard(
        t,
        header: '${deviceLabel(_device, t)}  ·  ${levelLabel(_level, t)}',
        warmup: w.warmupSeconds,
        intervals: w.intervals,
        work: w.workSeconds,
        rest: w.restSeconds,
        cooldown: w.cooldownSeconds,
      ),
    ];
  }

  List<Widget> _customConfig(Translations t) {
    return <Widget>[
      DSCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: <Widget>[
            DSStepperRow(
              label: t.warmUp,
              value: _customWarmup,
              unit: 's',
              min: 0,
              max: 600,
              step: 5,
              onChanged: (int v) => setState(() => _customWarmup = v),
            ),
            const Divider(color: DS.divider, height: 1),
            DSStepperRow(
              label: t.intervals,
              value: _customIntervals,
              unit: 'x',
              min: 1,
              max: 50,
              step: 1,
              onChanged: (int v) => setState(() => _customIntervals = v),
            ),
            const Divider(color: DS.divider, height: 1),
            DSStepperRow(
              label: t.work,
              value: _customWork,
              unit: 's',
              min: 5,
              max: 600,
              step: 5,
              onChanged: (int v) => setState(() => _customWork = v),
            ),
            const Divider(color: DS.divider, height: 1),
            DSStepperRow(
              label: t.rest,
              value: _customRest,
              unit: 's',
              min: 0,
              max: 600,
              step: 5,
              onChanged: (int v) => setState(() => _customRest = v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _breakdownCard(
        t,
        header: null,
        warmup: _customWarmup,
        intervals: _customIntervals,
        work: _customWork,
        rest: _customRest,
        cooldown: 0,
      ),
    ];
  }

  Widget _breakdownCard(
    Translations t, {
    required String? header,
    required int warmup,
    required int intervals,
    required int work,
    required int rest,
    required int cooldown,
  }) {
    final int total = warmup + intervals * (work + rest) + cooldown;
    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t.yourTraining,
              style: DS.headline().copyWith(color: Colors.white)),
          if (header != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              header,
              style: DS.body(15).copyWith(color: DS.accent),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(color: DS.divider, height: 1),
          const SizedBox(height: 8),
          _detailRow(t.warmUp, _fmt(warmup)),
          _detailRow(t.intervals, '$intervals×'),
          _detailRow(t.work, _fmt(work)),
          _detailRow(t.rest, _fmt(rest)),
          _detailRow(t.coolDown, _fmt(cooldown)),
          const SizedBox(height: 8),
          const Divider(color: DS.divider, height: 1),
          const SizedBox(height: 8),
          _detailRow(t.totalApprox, _fmt(total)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label,
                style: DS.body(15).copyWith(color: DS.textSecondary)),
          ),
          Text(
            value,
            style: DS
                .body(15)
                .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _fmt(int seconds) {
    if (seconds <= 0) return '—';
    if (seconds < 60) return '$seconds sec';
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return s == 0 ? '$m min' : '$m min $s sec';
  }

  // MARK: - Timer

  Widget _timerView(Translations t) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  _c.reset();
                  setState(() => _showConfig = true);
                },
                child: DSChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.chevron_left,
                          color: Colors.white, size: 16),
                      Text(
                        t.back,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
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
    final String title = ok ? t.saved : t.saveError;
    final String? message = ok ? null : _c.saveErrorMessage;
    if (!ok && message == null) return;
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
            child: Text(t.ok, style: const TextStyle(color: DS.accent)),
          ),
        ],
      ),
    );
  }
}
