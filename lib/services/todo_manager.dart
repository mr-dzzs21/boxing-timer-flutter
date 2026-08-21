// Todo CRUD + daily reminder notification — 1:1 port of iOS TodoManager.swift.
//
// Persistence: shared_preferences (iOS: UserDefaults key "todos").
// Reminder: one repeating daily notification ("todo_daily") at the user's
// average app-open time (default 09:00 with fewer than 3 data points).
// Note: the notification body is hardcoded German — exactly as shipped in
// iOS v1.3.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:boxing_timer_flutter/core/language_manager.dart';
import 'package:boxing_timer_flutter/core/models.dart';
import 'package:boxing_timer_flutter/services/user_settings.dart';

class TodoManager extends ChangeNotifier {
  TodoManager({
    required SharedPreferences prefs,
    required UserSettings settings,
    required LanguageManager language,
  })  : _prefs = prefs,
        _settings = settings,
        _language = language {
    _load();
    _settings.addListener(scheduleReminderIfNeeded);
  }

  static const String _todosKey = 'todos';
  static const String _appOpenTimesKey = 'appOpenTimes';

  /// Numeric stand-in for the iOS notification identifier "todo_daily".
  static const int _notificationId = 1001;

  final SharedPreferences _prefs;
  final UserSettings _settings;
  final LanguageManager _language;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Random _random = Random();

  List<Todo> todos = <Todo>[];

  bool _notificationsReady = false;

  List<Todo> get open => todos.where((Todo t) => !t.isDone).toList();

  List<Todo> get done => todos.where((Todo t) => t.isDone).toList();

  void _load() {
    final raw = _prefs.getString(_todosKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        todos = decoded
            .map((dynamic e) => Todo.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        todos = <Todo>[];
      }
    }
  }

  Future<void> add(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    todos.add(Todo(
      id: _generateId(),
      title: trimmed,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    await _save();
    await scheduleReminderIfNeeded();
  }

  Future<void> toggle(Todo todo) async {
    final index = todos.indexWhere((Todo t) => t.id == todo.id);
    if (index == -1) return;
    todos[index].isDone = !todos[index].isDone;
    notifyListeners();
    await _save();
    await scheduleReminderIfNeeded();
  }

  Future<void> deleteIds(List<String> ids) async {
    todos.removeWhere((Todo t) => ids.contains(t.id));
    notifyListeners();
    await _save();
    await scheduleReminderIfNeeded();
  }

  // MARK: - Usage tracking (iOS: recordAppOpen)

  /// Records the current time of day so the daily reminder can fire at the
  /// user's average open time. Opens between 00:00 and 06:59 are ignored;
  /// only the last 20 opens are kept.
  Future<void> recordAppOpen() async {
    final now = DateTime.now();
    if (now.hour < 7) return;
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    var opens = _loadOpenTimes()..add(minutesSinceMidnight);
    if (opens.length > 20) {
      opens = opens.sublist(opens.length - 20);
    }
    await _prefs.setStringList(
      _appOpenTimesKey,
      opens.map((int m) => m.toString()).toList(),
    );
  }

  List<int> _loadOpenTimes() {
    final stored = _prefs.getStringList(_appOpenTimesKey) ?? <String>[];
    return stored
        .map((String s) => int.tryParse(s))
        .whereType<int>()
        .toList();
  }

  /// Average open time; defaults to 09:00 with fewer than 3 data points.
  ({int hour, int minute}) _averageNotificationTime() {
    final opens = _loadOpenTimes();
    if (opens.length < 3) return (hour: 9, minute: 0);
    final avg = opens.reduce((int a, int b) => a + b) ~/ opens.length;
    return (hour: avg ~/ 60, minute: avg % 60);
  }

  // MARK: - Notifications (iOS: scheduleNotificationIfNeeded)

  Future<void> scheduleReminderIfNeeded() async {
    if (!_settings.todoNotificationsEnabled) {
      await cancelNotifications();
      return;
    }
    final openTodos = open;
    if (openTodos.isEmpty) {
      await cancelNotifications();
      return;
    }

    try {
      await _ensureNotificationsReady();

      final Translations t = _language.t;
      final body = openTodos.length == 1
          ? t.todoNotificationSingle
          : t.todoNotificationMultiple
              .replaceFirst('%d', openTodos.length.toString());

      final time = _averageNotificationTime();
      final now = DateTime.now();
      var next =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      await _notifications.cancel(_notificationId);
      await _notifications.zonedSchedule(
        _notificationId,
        'Box Interval Timer',
        body,
        tz.TZDateTime.from(next, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_daily',
            'Todo Reminders',
            channelDescription: 'Daily reminder for open todos',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Notifications are best-effort (permission denied, unsupported
      // platform, tests) — never break todo CRUD because of them.
      debugPrint('TodoManager: could not schedule reminder: $e');
    }
  }

  Future<void> cancelNotifications() async {
    try {
      await _notifications.cancel(_notificationId);
    } catch (e) {
      debugPrint('TodoManager: could not cancel reminder: $e');
    }
  }

  Future<void> _ensureNotificationsReady() async {
    if (_notificationsReady) return;
    tz_data.initializeTimeZones();
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _notificationsReady = true;
  }

  // MARK: - Persistence

  Future<void> _save() async {
    await _prefs.setString(
      _todosKey,
      jsonEncode(todos.map((Todo t) => t.toJson()).toList()),
    );
  }

  /// UUID-style id (iOS uses `UUID()`); avoids an extra package dependency.
  String _generateId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final salt = _random.nextInt(0x7FFFFFFF).toRadixString(16);
    return '$time-$salt';
  }

  @override
  void dispose() {
    _settings.removeListener(scheduleReminderIfNeeded);
    super.dispose();
  }
}
