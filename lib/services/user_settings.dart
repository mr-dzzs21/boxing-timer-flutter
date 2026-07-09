import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port of the iOS `UserSettings` (UserSettings.swift).
///
/// Defaults match iOS first-launch behavior: sound, vibration and the
/// 10-second warning are ON by default; todo notifications are OFF until the
/// user enables them.
class UserSettings extends ChangeNotifier {
  UserSettings._(
    this._prefs, {
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool warningEnabled,
    required bool todoNotificationsEnabled,
  })  : _soundEnabled = soundEnabled,
        _vibrationEnabled = vibrationEnabled,
        _warningEnabled = warningEnabled,
        _todoNotificationsEnabled = todoNotificationsEnabled;

  static const String _soundKey = 'soundEnabled';
  static const String _vibrationKey = 'vibrationEnabled';
  static const String _warningKey = 'warningEnabled';
  static const String _todoNotificationsKey = 'todoNotificationsEnabled';

  final SharedPreferences _prefs;

  bool _soundEnabled;
  bool _vibrationEnabled;
  bool _warningEnabled;
  bool _todoNotificationsEnabled;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get warningEnabled => _warningEnabled;
  bool get todoNotificationsEnabled => _todoNotificationsEnabled;

  static Future<UserSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserSettings._(
      prefs,
      soundEnabled: prefs.getBool(_soundKey) ?? true,
      vibrationEnabled: prefs.getBool(_vibrationKey) ?? true,
      warningEnabled: prefs.getBool(_warningKey) ?? true,
      todoNotificationsEnabled: prefs.getBool(_todoNotificationsKey) ?? false,
    );
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    notifyListeners();
    await _prefs.setBool(_soundKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled == value) return;
    _vibrationEnabled = value;
    notifyListeners();
    await _prefs.setBool(_vibrationKey, value);
  }

  Future<void> setWarningEnabled(bool value) async {
    if (_warningEnabled == value) return;
    _warningEnabled = value;
    notifyListeners();
    await _prefs.setBool(_warningKey, value);
  }

  Future<void> setTodoNotificationsEnabled(bool value) async {
    if (_todoNotificationsEnabled == value) return;
    _todoNotificationsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_todoNotificationsKey, value);
  }
}
