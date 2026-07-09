import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../core/models.dart';
import '../services/history_repository.dart';

/// Port of the iOS `HistoryView` + `WorkoutDetailView`.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutRecord> _workouts = <WorkoutRecord>[];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<WorkoutRecord> all = await HistoryRepository.instance.all();
    if (!mounted) return;
    setState(() {
      _workouts = all;
      _loaded = true;
    });
  }

  String _formatDate(DateTime date, String locale) {
    try {
      return DateFormat.yMMMd(locale).add_Hm().format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
  }

  String _formatDuration(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    final LanguageManager lang = context.watch<LanguageManager>();
    final Translations t = lang.t;

    return Container(
      color: DS.bg,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: <Widget>[
                  Text(
                    t.historyTitle,
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  if (_workouts.isNotEmpty)
                    TextButton(
                      onPressed: _confirmDeleteAll,
                      child: Text(
                        t.deleteAll,
                        style: const TextStyle(color: DS.phaseRest),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: !_loaded
                  ? const SizedBox.shrink()
                  : _workouts.isEmpty
                      ? _emptyState(t)
                      : RefreshIndicator(
                          color: DS.accent,
                          onRefresh: _reload,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _workouts.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final WorkoutRecord w = _workouts[index];
                              return Dismissible(
                                key: ValueKey<Object>(w.id ?? w.date),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding:
                                      const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: DS.phaseRest,
                                    borderRadius: BorderRadius.circular(
                                        DS.radiusCard),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (_) async {
                                  final int? id = w.id;
                                  setState(() => _workouts.removeAt(index));
                                  if (id != null) {
                                    await HistoryRepository.instance
                                        .deleteById(id);
                                  }
                                },
                                child: _row(w, lang, t),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(Translations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.history, size: 56, color: DS.textTertiary),
          const SizedBox(height: 12),
          Text(t.noWorkouts,
              style: DS.display(22).copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              t.noWorkoutsDesc,
              textAlign: TextAlign.center,
              style: DS.body(14).copyWith(color: DS.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(WorkoutRecord w, LanguageManager lang, Translations t) {
    return InkWell(
      borderRadius: BorderRadius.circular(DS.radiusCard),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WorkoutDetailPage(workout: w),
          ),
        );
        _reload();
      },
      child: DSCard(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    lang.localizedPresetName(w.sportName),
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(w.mode,
                      style: DS.body(14).copyWith(color: DS.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(w.date, lang.current.code),
                    style: DS.body(12).copyWith(color: DS.textTertiary),
                  ),
                ],
              ),
            ),
            Text(
              _formatDuration(w.totalDuration),
              style: DS.body(15).copyWith(color: DS.accent),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAll() {
    final Translations t = context.read<LanguageManager>().t;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: DS.surface,
        title: Text(t.confirmDeleteAll,
            style: const TextStyle(color: Colors.white, fontSize: 17)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text(t.cancel, style: const TextStyle(color: DS.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await HistoryRepository.instance.deleteAll();
              _reload();
            },
            child:
                Text(t.deleteAll, style: const TextStyle(color: DS.phaseRest)),
          ),
        ],
      ),
    );
  }
}

/// Detail page with general info + notes editor + per-mode details.
class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({super.key, required this.workout});

  final WorkoutRecord workout;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.workout.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LanguageManager lang = context.watch<LanguageManager>();
    final Translations t = lang.t;
    final WorkoutRecord w = widget.workout;

    return Scaffold(
      backgroundColor: DS.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    t.workoutDetails,
                    style: DS.headline(17).copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _section(t.general, <Widget>[
                    _kv(t.sport, lang.localizedPresetName(w.sportName)),
                    _kv(t.mode, w.mode),
                    _kv(
                      t.date,
                      DateFormat.yMMMMd(lang.current.code)
                          .add_Hm()
                          .format(w.date),
                    ),
                    _kv(
                      t.duration,
                      '${w.totalDuration ~/ 60}:${(w.totalDuration % 60).toString().padLeft(2, '0')} min',
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _section(t.notes, <Widget>[
                    TextField(
                      controller: _notes,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: DS.accent,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: DS.surfaceHi,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DSPrimaryButton(
                      label: t.saveNotes,
                      onPressed: () async {
                        final WorkoutRecord updated = WorkoutRecord(
                          id: w.id,
                          date: w.date,
                          mode: w.mode,
                          sportName: w.sportName,
                          totalDuration: w.totalDuration,
                          rounds: w.rounds,
                          roundSeconds: w.roundSeconds,
                          restSeconds: w.restSeconds,
                          warmupSeconds: w.warmupSeconds,
                          intervals: w.intervals,
                          workSeconds: w.workSeconds,
                          notes: _notes.text.trim().isEmpty
                              ? null
                              : _notes.text.trim(),
                        );
                        await HistoryRepository.instance.update(updated);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (w.mode == modeFightTimer)
                    _section(t.fightTimerDetails, <Widget>[
                      _kv(t.rounds, '${w.rounds}'),
                      _kv(t.roundTime, '${w.roundSeconds ~/ 60} min'),
                      _kv(t.rest, '${w.restSeconds}s'),
                      _kv(t.warmUp, '${w.warmupSeconds}s'),
                    ]),
                  if (w.mode == modeIntervals)
                    _section(t.intervalDetails, <Widget>[
                      _kv(t.intervals, '${w.intervals}'),
                      _kv(t.work, '${w.workSeconds}s'),
                      _kv(t.rest, '${w.restSeconds}s'),
                      _kv(t.warmUp, '${w.warmupSeconds}s'),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: DS.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        DSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child:
                Text(label, style: DS.body(15).copyWith(color: Colors.white)),
          ),
          Text(value, style: DS.body(15).copyWith(color: DS.textSecondary)),
        ],
      ),
    );
  }
}
