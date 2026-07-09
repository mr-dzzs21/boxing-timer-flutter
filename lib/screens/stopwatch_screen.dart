import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';

/// Port of the iOS `StopwatchView` — big rounded digits, lap list.
class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  final List<Duration> _laps = <Duration>[];
  Duration _lastLapAt = Duration.zero;

  bool get _isRunning => _stopwatch.isRunning;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startStop() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _ticker?.cancel();
        _ticker = null;
      } else {
        _stopwatch.start();
        _ticker = Timer.periodic(
          const Duration(milliseconds: 33),
          (_) => setState(() {}),
        );
      }
    });
  }

  void _lapOrReset() {
    setState(() {
      if (_stopwatch.isRunning) {
        final Duration now = _stopwatch.elapsed;
        _laps.insert(0, now - _lastLapAt);
        _lastLapAt = now;
      } else {
        _stopwatch.reset();
        _laps.clear();
        _lastLapAt = Duration.zero;
      }
    });
  }

  String _format(Duration d) {
    final int minutes = d.inMinutes;
    final int seconds = d.inSeconds % 60;
    final int centis = (d.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${centis.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Translations t = context.watch<LanguageManager>().t;
    final bool canLapOrReset =
        _isRunning || _stopwatch.elapsed > Duration.zero;

    return Container(
      color: DS.bg,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                t.stopwatchTitle,
                style: DS.headline(17).copyWith(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 32),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _format(_stopwatch.elapsed),
                  style: DS.timer(74).copyWith(color: Colors.white),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _roundTextButton(
                  label: _isRunning ? t.stopwatchLap : t.stopwatchReset,
                  background: DS.controlFill,
                  border: DS.controlStroke,
                  enabled: canLapOrReset,
                  onTap: _lapOrReset,
                ),
                const SizedBox(width: 40),
                _roundTextButton(
                  label: _isRunning ? t.stopwatchStop : t.stopwatchStart,
                  background: _isRunning ? DS.phaseRest : DS.phaseRound,
                  border: null,
                  enabled: true,
                  onTap: _startStop,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_laps.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _laps.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const Divider(color: DS.divider, height: 1),
                  itemBuilder: (BuildContext context, int index) {
                    final Duration lap = _laps[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: <Widget>[
                          Text(
                            '${t.stopwatchLap} ${_laps.length - index}',
                            style: DS
                                .body(15)
                                .copyWith(color: DS.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            _format(lap),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFeatures: <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _roundTextButton({
    required String label,
    required Color background,
    required Color? border,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border:
                border == null ? null : Border.all(color: border, width: 1.5),
            boxShadow: border == null
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
