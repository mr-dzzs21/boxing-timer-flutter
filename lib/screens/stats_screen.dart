import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/language_manager.dart';
import '../core/models.dart';
import '../services/history_repository.dart';

/// Port of the iOS `StatsView` incl. the labeled, weekday-aligned heatmap.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<WorkoutRecord> _workouts = <WorkoutRecord>[];

  int _totalWorkouts = 0;
  int _totalDuration = 0;
  int _last7Days = 0;
  int _streak = 0;
  bool _has12RoundFightWorkout = false;
  String _favoriteSport = '—';

  @override
  void initState() {
    super.initState();
    // Same rationale as HistoryScreen: the root IndexedStack keeps this
    // screen alive across tab switches, so without this listener a newly
    // completed workout would never update the stats/heatmap/achievements
    // until the app restarts.
    HistoryRepository.instance.addListener(_onHistoryChanged);
    _reload();
  }

  @override
  void dispose() {
    HistoryRepository.instance.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (!mounted) return;
    _reload();
  }

  Future<void> _reload() async {
    final List<WorkoutRecord> all = await HistoryRepository.instance.all();
    if (!mounted) return;
    setState(() {
      _workouts = all;
      _compute();
    });
  }

  void _compute() {
    _totalWorkouts = _workouts.length;
    _totalDuration =
        _workouts.fold(0, (int sum, WorkoutRecord w) => sum + w.totalDuration);

    final DateTime now = DateTime.now();
    final DateTime weekAgo = now.subtract(const Duration(days: 7));
    _last7Days =
        _workouts.where((WorkoutRecord w) => w.date.isAfter(weekAgo)).length;

    // Streak: aufeinanderfolgende Trainingstage — HEUTE zählt mit.
    final Set<DateTime> days = _workouts
        .map((WorkoutRecord w) =>
            DateTime(w.date.year, w.date.month, w.date.day))
        .toSet();
    DateTime cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor) &&
        days.contains(cursor.subtract(const Duration(days: 1)))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    _streak = streak;

    // Matches iOS StatsViewModel.calculateAchievements: at least one Fight
    // Timer workout with >=12 rounds (e.g. the default "Boxen" preset).
    _has12RoundFightWorkout = _workouts.any(
      (WorkoutRecord w) => w.rounds >= 12 && w.mode == modeFightTimer,
    );

    final Map<String, int> counts = <String, int>{};
    for (final WorkoutRecord w in _workouts) {
      counts[w.sportName] = (counts[w.sportName] ?? 0) + 1;
    }
    _favoriteSport = counts.isEmpty
        ? '—'
        : counts.entries
            .reduce((MapEntry<String, int> a, MapEntry<String, int> b) =>
                a.value >= b.value ? a : b)
            .key;
  }

  String _formatTotalTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final LanguageManager lang = context.watch<LanguageManager>();
    final Translations t = lang.t;

    return Container(
      color: DS.bg,
      child: SafeArea(
        child: RefreshIndicator(
          color: DS.accent,
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Center(
                child: Text(
                  t.statsTitle,
                  style: DS.headline(17).copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      title: t.workoutsLabel,
                      value: '$_totalWorkouts',
                      icon: Icons.local_fire_department,
                      color: DS.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: t.streak,
                      value: '$_streak',
                      icon: Icons.calendar_month,
                      color: DS.phaseDone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      title: t.thisWeek,
                      value: '$_last7Days',
                      icon: Icons.bar_chart,
                      color: DS.phaseRound,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: t.totalTime,
                      value: _formatTotalTime(_totalDuration),
                      icon: Icons.schedule,
                      color: const Color(0xFFB07CF7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(t.heatmapTitle,
                  style: DS.headline().copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              _Heatmap(workouts: _workouts, t: t, locale: lang.current.code),
              const SizedBox(height: 24),
              Text(t.achievementsTitle,
                  style: DS.headline().copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    _AchievementCard(
                      // iOS: currentStreak >= 10 (a 10-day streak, not a
                      // workout count — was wrongly mapped to workout count).
                      title: t.achievementWarriorTitle,
                      description: t.achievementWarriorDesc,
                      icon: Icons.sports_mma,
                      unlocked: _streak >= 10,
                    ),
                    _AchievementCard(
                      // iOS: totalDuration >= 28800s (8 hours total training
                      // time, not a workout count).
                      title: t.achievementHardWorkerTitle,
                      description: t.achievementHardWorkerDesc,
                      icon: Icons.fitness_center,
                      unlocked: _totalDuration >= 28800,
                    ),
                    _AchievementCard(
                      // iOS: at least one Fight Timer workout with >=12
                      // rounds (not the streak).
                      title: t.achievementProFighterTitle,
                      description: t.achievementProFighterDesc,
                      icon: Icons.emoji_events,
                      unlocked: _has12RoundFightWorkout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(t.favoriteSport,
                  style: DS.headline().copyWith(color: Colors.white)),
              const SizedBox(height: 10),
              DSCard(
                child: Text(
                  _favoriteSport == '—'
                      ? '—'
                      : lang.localizedPresetName(_favoriteSport),
                  style: DS.display(24).copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(DS.radiusCard),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: DS.display(26).copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: DS.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DS.surface,
          borderRadius: BorderRadius.circular(DS.radiusCard),
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: unlocked
                    ? DS.accent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: unlocked ? DS.accent : DS.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: unlocked ? Colors.white : DS.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: DS.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Weekday-aligned minutes-per-day heatmap (18 weeks) — port of the iOS
/// `HeatmapView` incl. month labels, weekday labels, today marker, legend.
class _Heatmap extends StatelessWidget {
  const _Heatmap({
    required this.workouts,
    required this.t,
    required this.locale,
  });

  final List<WorkoutRecord> workouts;
  final Translations t;
  final String locale;

  static const int _weeks = 18;
  static const double _cell = 13;
  static const double _spacing = 3;
  static const double _weekdayColWidth = 20;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    // Wochenstart: Montag (EU-Konvention, wie iOS-Port).
    final DateTime thisWeekStart =
        today.subtract(Duration(days: today.weekday - 1));
    final List<DateTime> weekStarts = List<DateTime>.generate(
      _weeks,
      (int i) => thisWeekStart.subtract(Duration(days: 7 * (_weeks - 1 - i))),
    );

    final Map<DateTime, int> minutes = <DateTime, int>{};
    for (final WorkoutRecord w in workouts) {
      final DateTime day = DateTime(w.date.year, w.date.month, w.date.day);
      minutes[day] = (minutes[day] ?? 0) + w.totalDuration ~/ 60;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _monthHeader(weekStarts),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _weekdayColumn(),
                for (final DateTime ws in weekStarts) ...<Widget>[
                  const SizedBox(width: _spacing),
                  Column(
                    children: <Widget>[
                      for (int row = 0; row < 7; row++) ...<Widget>[
                        if (row > 0) const SizedBox(height: _spacing),
                        _cellFor(
                          ws.add(Duration(days: row)),
                          today,
                          minutes,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            _legend(),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader(List<DateTime> weekStarts) {
    final List<Widget> markers = <Widget>[];
    int lastMonth = -1;
    double lastX = -100;
    for (int col = 0; col < weekStarts.length; col++) {
      final int month = weekStarts[col].month;
      if (month == lastMonth) continue;
      lastMonth = month;
      final double x = _weekdayColWidth + _spacing + col * (_cell + _spacing);
      if (x - lastX < 26) continue;
      lastX = x;
      String label;
      try {
        label = DateFormat.MMM(locale).format(weekStarts[col]);
      } catch (_) {
        label = DateFormat.MMM().format(weekStarts[col]);
      }
      markers.add(Positioned(
        left: x,
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, color: DS.textSecondary),
        ),
      ));
    }
    return SizedBox(
      height: 12,
      width: double.infinity,
      child: Stack(children: markers),
    );
  }

  Widget _weekdayColumn() {
    return Column(
      children: <Widget>[
        for (int row = 0; row < 7; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: _spacing),
          SizedBox(
            width: _weekdayColWidth,
            height: _cell,
            child: row.isEven
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _weekdayLabel(row),
                      style: const TextStyle(
                          fontSize: 9, color: DS.textSecondary),
                    ),
                  )
                : null,
          ),
        ],
      ],
    );
  }

  String _weekdayLabel(int row) {
    // row 0 = Montag
    final DateTime monday = DateTime(2024, 1, 1); // ein Montag
    try {
      return DateFormat.E(locale).format(monday.add(Duration(days: row)));
    } catch (_) {
      return DateFormat.E().format(monday.add(Duration(days: row)));
    }
  }

  Widget _cellFor(DateTime date, DateTime today, Map<DateTime, int> minutes) {
    final bool isFuture = date.isAfter(today);
    final bool isToday = date == today;
    final int mins = minutes[DateTime(date.year, date.month, date.day)] ?? 0;
    return Container(
      width: _cell,
      height: _cell,
      decoration: BoxDecoration(
        color: isFuture ? Colors.transparent : _color(mins),
        borderRadius: BorderRadius.circular(3),
        border: isToday ? Border.all(color: Colors.white, width: 1.5) : null,
      ),
    );
  }

  Widget _legend() {
    return Row(
      children: <Widget>[
        Text(t.heatmapLess,
            style: const TextStyle(fontSize: 9, color: DS.textSecondary)),
        const SizedBox(width: 4),
        for (int level = 0; level < 5; level++) ...<Widget>[
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _levelColor(level),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 4),
        Text(t.heatmapMore,
            style: const TextStyle(fontSize: 9, color: DS.textSecondary)),
        const Spacer(),
        Text(t.heatmapUnit,
            style: const TextStyle(fontSize: 9, color: DS.textSecondary)),
      ],
    );
  }

  Color _color(int mins) {
    if (mins <= 0) return Colors.grey.withValues(alpha: 0.15);
    if (mins < 15) return DS.phaseRound.withValues(alpha: 0.35);
    if (mins < 30) return DS.phaseRound.withValues(alpha: 0.6);
    if (mins < 45) return DS.phaseRound.withValues(alpha: 0.8);
    return DS.phaseRound;
  }

  Color _levelColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey.withValues(alpha: 0.15);
      case 1:
        return DS.phaseRound.withValues(alpha: 0.35);
      case 2:
        return DS.phaseRound.withValues(alpha: 0.6);
      case 3:
        return DS.phaseRound.withValues(alpha: 0.8);
      default:
        return DS.phaseRound;
    }
  }
}
