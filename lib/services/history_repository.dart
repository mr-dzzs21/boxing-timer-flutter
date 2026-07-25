// Workout history persistence — Flutter port of the iOS Core Data stack
// (Persistence.swift + WorkoutHistoryEntity). Schema mirrors WorkoutRecord.

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:boxing_timer_flutter/core/models.dart';

/// Extends ChangeNotifier so History/Stats screens can react the instant a
/// workout is saved elsewhere (e.g. auto-saved by the timer on completion).
/// Without this, screens kept alive by the root IndexedStack would only
/// ever load data once in initState and never see later writes — a
/// completed workout would look "lost" until the app is restarted.
class HistoryRepository extends ChangeNotifier {
  HistoryRepository._();

  static final HistoryRepository instance = HistoryRepository._();

  static const String _dbName = 'boxing_timer.db';
  static const String _table = 'workouts';

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;
    final path = p.join(await getDatabasesPath(), _dbName);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date INTEGER NOT NULL,
            mode TEXT NOT NULL,
            sportName TEXT NOT NULL,
            totalDuration INTEGER NOT NULL DEFAULT 0,
            rounds INTEGER NOT NULL DEFAULT 0,
            roundSeconds INTEGER NOT NULL DEFAULT 0,
            restSeconds INTEGER NOT NULL DEFAULT 0,
            warmupSeconds INTEGER NOT NULL DEFAULT 0,
            intervals INTEGER NOT NULL DEFAULT 0,
            workSeconds INTEGER NOT NULL DEFAULT 0,
            notes TEXT
          )
        ''');
      },
    );
    _db = db;
    return db;
  }

  /// Inserts [record], assigns the generated row id back onto it and
  /// returns the id.
  Future<int> insert(WorkoutRecord record) async {
    final db = await _database;
    final id = await db.insert(_table, record.toMap());
    record.id = id;
    notifyListeners();
    return id;
  }

  /// Updates an existing record (matched by id). No-op if the record has
  /// never been inserted.
  Future<void> update(WorkoutRecord record) async {
    final id = record.id;
    if (id == null) return;
    final db = await _database;
    await db.update(
      _table,
      record.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    notifyListeners();
  }

  Future<void> deleteById(int id) async {
    final db = await _database;
    await db.delete(_table, where: 'id = ?', whereArgs: <Object?>[id]);
    notifyListeners();
  }

  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_table);
    notifyListeners();
  }

  /// All saved workouts, newest first (matches the iOS history fetch,
  /// sorted by date descending).
  Future<List<WorkoutRecord>> all() async {
    final db = await _database;
    final rows = await db.query(_table, orderBy: 'date DESC');
    return rows.map(WorkoutRecord.fromMap).toList();
  }
}
