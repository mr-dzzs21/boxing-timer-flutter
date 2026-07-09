// Core data models — 1:1 port of iOS ModelsAndStubs.swift (v1.3).
//
// Pure model layer: no Flutter imports besides foundation.

import 'package:flutter/foundation.dart';

import 'package:boxing_timer_flutter/core/language_manager.dart';

/// Workout mode identifiers, matching the iOS `WorkoutMode` raw values
/// stored in workout history.
const String modeFightTimer = 'Fight Timer';
const String modeIntervals = 'Intervals';

enum TimerPhase { warmup, round, rest, cooldown, finished }

enum TimerStatus { idle, running, paused }

@immutable
class FightPreset {
  final String id;
  final String name;
  final int rounds;
  final int roundSeconds;
  final int restSeconds;
  final int warmupSeconds;
  final bool isCustom;

  const FightPreset({
    required this.id,
    required this.name,
    required this.rounds,
    required this.roundSeconds,
    required this.restSeconds,
    required this.warmupSeconds,
    this.isCustom = false,
  });

  FightPreset copyWith({
    String? id,
    String? name,
    int? rounds,
    int? roundSeconds,
    int? restSeconds,
    int? warmupSeconds,
    bool? isCustom,
  }) {
    return FightPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      rounds: rounds ?? this.rounds,
      roundSeconds: roundSeconds ?? this.roundSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      warmupSeconds: warmupSeconds ?? this.warmupSeconds,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'rounds': rounds,
        'roundSeconds': roundSeconds,
        'restSeconds': restSeconds,
        'warmupSeconds': warmupSeconds,
        'isCustom': isCustom,
      };

  factory FightPreset.fromJson(Map<String, dynamic> json) => FightPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        rounds: json['rounds'] as int,
        roundSeconds: json['roundSeconds'] as int,
        restSeconds: json['restSeconds'] as int,
        warmupSeconds: json['warmupSeconds'] as int,
        isCustom: json['isCustom'] as bool? ?? false,
      );

  /// Exact values from iOS `FightPreset.defaultPresets`
  /// (ModelsAndStubs.swift). Names stay German — localization happens via
  /// `LanguageManager.localizedPresetName`.
  static final List<FightPreset> defaultPresets = <FightPreset>[
    const FightPreset(
        id: 'default-boxen',
        name: '🥊 Boxen',
        warmupSeconds: 5,
        rounds: 12,
        roundSeconds: 180,
        restSeconds: 60),
    const FightPreset(
        id: 'default-mma',
        name: '🥋 MMA',
        warmupSeconds: 5,
        rounds: 3,
        roundSeconds: 300,
        restSeconds: 60),
    const FightPreset(
        id: 'default-k1',
        name: '🦵 K1',
        warmupSeconds: 5,
        rounds: 3,
        roundSeconds: 180,
        restSeconds: 60),
    const FightPreset(
        id: 'default-muay-thai',
        name: '🇹🇭 Muay Thai',
        warmupSeconds: 5,
        rounds: 5,
        roundSeconds: 180,
        restSeconds: 120),
    const FightPreset(
        id: 'default-bjj',
        name: '🤼 BJJ',
        warmupSeconds: 10,
        rounds: 1,
        roundSeconds: 300,
        restSeconds: 0),
    const FightPreset(
        id: 'default-judo',
        name: '🥋 Judo',
        warmupSeconds: 10,
        rounds: 1,
        roundSeconds: 240,
        restSeconds: 0),
    const FightPreset(
        id: 'default-ringen',
        name: '🤼 Ringen',
        warmupSeconds: 10,
        rounds: 3,
        roundSeconds: 120,
        restSeconds: 30),
    const FightPreset(
        id: 'default-taekwondo',
        name: '🥋 Taekwondo',
        warmupSeconds: 5,
        rounds: 3,
        roundSeconds: 120,
        restSeconds: 60),
  ];
}

enum IntervalDevice { running, treadmill, airBike, bagWork }

/// German raw values exactly as stored by iOS (`IntervalDevice` raw values).
/// Used as the canonical `sportName` in history so that
/// `LanguageManager.localizedPresetName` can translate saved records.
extension IntervalDeviceRaw on IntervalDevice {
  String get rawValue {
    switch (this) {
      case IntervalDevice.running:
        return '🏃 Draußen laufen';
      case IntervalDevice.treadmill:
        return '🏋️ Laufband';
      case IntervalDevice.airBike:
        return '🚴 AirBike';
      case IntervalDevice.bagWork:
        return '🥊 Sandsack';
    }
  }
}

String deviceLabel(IntervalDevice d, Translations t) {
  switch (d) {
    case IntervalDevice.running:
      return t.deviceRunning;
    case IntervalDevice.treadmill:
      return t.deviceTreadmill;
    case IntervalDevice.airBike:
      return t.deviceAirBike;
    case IntervalDevice.bagWork:
      return t.deviceBagWork;
  }
}

enum IntervalLevel { beginner, intermediate, advanced }

/// German raw values exactly as stored by iOS (`IntervalLevel` raw values).
extension IntervalLevelRaw on IntervalLevel {
  String get rawValue {
    switch (this) {
      case IntervalLevel.beginner:
        return 'Anfänger';
      case IntervalLevel.intermediate:
        return 'Fortgeschritten';
      case IntervalLevel.advanced:
        return 'Profi';
    }
  }
}

String levelLabel(IntervalLevel l, Translations t) {
  switch (l) {
    case IntervalLevel.beginner:
      return t.levelBeginner;
    case IntervalLevel.intermediate:
      return t.levelIntermediate;
    case IntervalLevel.advanced:
      return t.levelAdvanced;
  }
}

@immutable
class IntervalWorkout {
  final IntervalDevice device;
  final IntervalLevel level;
  final int warmupSeconds;
  final int intervals;
  final int workSeconds;
  final int restSeconds;
  final int cooldownSeconds;

  const IntervalWorkout({
    required this.device,
    required this.level,
    required this.warmupSeconds,
    required this.intervals,
    required this.workSeconds,
    required this.restSeconds,
    required this.cooldownSeconds,
  });

  IntervalWorkout copyWith({
    IntervalDevice? device,
    IntervalLevel? level,
    int? warmupSeconds,
    int? intervals,
    int? workSeconds,
    int? restSeconds,
    int? cooldownSeconds,
  }) {
    return IntervalWorkout(
      device: device ?? this.device,
      level: level ?? this.level,
      warmupSeconds: warmupSeconds ?? this.warmupSeconds,
      intervals: intervals ?? this.intervals,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }

  /// German display name as stored by iOS (`IntervalWorkout.displayName`),
  /// e.g. "🥊 Sandsack - Anfänger".
  String get displayName => '${device.rawValue} - ${level.rawValue}';

  /// Exact iOS matrix from `IntervalWorkout.workout(for:level:)`.
  static IntervalWorkout workoutFor(IntervalDevice device, IntervalLevel level) {
    switch ((device, level)) {
      // Running
      case (IntervalDevice.running, IntervalLevel.beginner):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 300,
            intervals: 8,
            workSeconds: 30,
            restSeconds: 60,
            cooldownSeconds: 180);
      case (IntervalDevice.running, IntervalLevel.intermediate):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 300,
            intervals: 10,
            workSeconds: 45,
            restSeconds: 60,
            cooldownSeconds: 180);
      case (IntervalDevice.running, IntervalLevel.advanced):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 360,
            intervals: 12,
            workSeconds: 60,
            restSeconds: 60,
            cooldownSeconds: 240);

      // Treadmill
      case (IntervalDevice.treadmill, IntervalLevel.beginner):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 300,
            intervals: 8,
            workSeconds: 30,
            restSeconds: 60,
            cooldownSeconds: 180);
      case (IntervalDevice.treadmill, IntervalLevel.intermediate):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 300,
            intervals: 10,
            workSeconds: 45,
            restSeconds: 60,
            cooldownSeconds: 180);
      case (IntervalDevice.treadmill, IntervalLevel.advanced):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 360,
            intervals: 15,
            workSeconds: 60,
            restSeconds: 60,
            cooldownSeconds: 240);

      // AirBike
      case (IntervalDevice.airBike, IntervalLevel.beginner):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 180,
            intervals: 6,
            workSeconds: 20,
            restSeconds: 60,
            cooldownSeconds: 120);
      case (IntervalDevice.airBike, IntervalLevel.intermediate):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 240,
            intervals: 10,
            workSeconds: 30,
            restSeconds: 60,
            cooldownSeconds: 180);
      case (IntervalDevice.airBike, IntervalLevel.advanced):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 300,
            intervals: 15,
            workSeconds: 40,
            restSeconds: 50,
            cooldownSeconds: 240);

      // Bag Work
      case (IntervalDevice.bagWork, IntervalLevel.beginner):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 180,
            intervals: 6,
            workSeconds: 30,
            restSeconds: 60,
            cooldownSeconds: 120);
      case (IntervalDevice.bagWork, IntervalLevel.intermediate):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 240,
            intervals: 10,
            workSeconds: 45,
            restSeconds: 50,
            cooldownSeconds: 180);
      case (IntervalDevice.bagWork, IntervalLevel.advanced):
        return IntervalWorkout(
            device: device,
            level: level,
            warmupSeconds: 300,
            intervals: 15,
            workSeconds: 90,
            restSeconds: 40,
            cooldownSeconds: 240);
    }
  }
}

/// One saved workout — mirrors the iOS Core Data `WorkoutHistoryEntity`.
/// `id` is mutable so the history repository can assign the row id after
/// insert.
class WorkoutRecord {
  int? id;
  final DateTime date;
  final String mode;
  final String sportName;
  final int totalDuration;
  final int rounds;
  final int roundSeconds;
  final int restSeconds;
  final int warmupSeconds;
  final int intervals;
  final int workSeconds;
  final String? notes;

  WorkoutRecord({
    this.id,
    required this.date,
    required this.mode,
    required this.sportName,
    required this.totalDuration,
    this.rounds = 0,
    this.roundSeconds = 0,
    this.restSeconds = 0,
    this.warmupSeconds = 0,
    this.intervals = 0,
    this.workSeconds = 0,
    this.notes,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'date': date.millisecondsSinceEpoch,
        'mode': mode,
        'sportName': sportName,
        'totalDuration': totalDuration,
        'rounds': rounds,
        'roundSeconds': roundSeconds,
        'restSeconds': restSeconds,
        'warmupSeconds': warmupSeconds,
        'intervals': intervals,
        'workSeconds': workSeconds,
        'notes': notes,
      };

  factory WorkoutRecord.fromMap(Map<String, Object?> map) => WorkoutRecord(
        id: map['id'] as int?,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        mode: map['mode'] as String,
        sportName: map['sportName'] as String,
        totalDuration: (map['totalDuration'] as int?) ?? 0,
        rounds: (map['rounds'] as int?) ?? 0,
        roundSeconds: (map['roundSeconds'] as int?) ?? 0,
        restSeconds: (map['restSeconds'] as int?) ?? 0,
        warmupSeconds: (map['warmupSeconds'] as int?) ?? 0,
        intervals: (map['intervals'] as int?) ?? 0,
        workSeconds: (map['workSeconds'] as int?) ?? 0,
        notes: map['notes'] as String?,
      );
}

class Todo {
  final String id;
  String title;
  bool isDone;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['isDone'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
