import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port of the iOS `UserSettings` (UserSettings.swift).
///
/// Defaults match iOS first-launch behavior: sound, vibration and the
/// 10-second warning are ON by default; todo notifications are OFF until the
/// user enables them.
class UserSettings extends ChangeNotifier {
  UserSettings(this._prefs)
      : _soundEnabled = _prefs.getBool(soundKey) ?? true,
        _vibrationEnabled = _prefs.getBool(vibrationKey) ?? true,
        _warningEnabled = _prefs.getBool(warningKey) ?? true,
        _todoNotificationsEnabled = _prefs.getBool(todoNotificationsKey) ?? false,
        _comboTrainerEnabled = _prefs.getBool(comboTrainerKey) ?? false,
        _comboUseNames = _prefs.getBool(comboUseNamesKey) ?? false;

  static const String soundKey = 'soundEnabled';
  static const String vibrationKey = 'vibrationEnabled';
  static const String warningKey = 'warningEnabled';
  static const String todoNotificationsKey = 'todoNotificationsEnabled';
  static const String comboTrainerKey = 'comboTrainerEnabled';
  static const String comboUseNamesKey = 'comboUseNames';

  final SharedPreferences _prefs;

  bool _soundEnabled;
  bool _vibrationEnabled;
  bool _warningEnabled;
  bool _todoNotificationsEnabled;
  bool _comboTrainerEnabled;
  bool _comboUseNames;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get warningEnabled => _warningEnabled;
  bool get todoNotificationsEnabled => _todoNotificationsEnabled;

  /// Combo Trainer: announce random punch combos during rounds (default off).
  bool get comboTrainerEnabled => _comboTrainerEnabled;

  /// Announce combos as names ("Jab, Cross") instead of numbers ("1 2").
  bool get comboUseNames => _comboUseNames;

  Future<void> setSoundEnabled(bool value) =>
      _updateSetting(soundKey, value, () => _soundEnabled = value, _soundEnabled);

  Future<void> setVibrationEnabled(bool value) =>
      _updateSetting(vibrationKey, value, () => _vibrationEnabled = value, _vibrationEnabled);

  Future<void> setWarningEnabled(bool value) =>
      _updateSetting(warningKey, value, () => _warningEnabled = value, _warningEnabled);

  Future<void> setTodoNotificationsEnabled(bool value) =>
      _updateSetting(todoNotificationsKey, value, () => _todoNotificationsEnabled = value, _todoNotificationsEnabled);

  Future<void> setComboTrainerEnabled(bool value) => _updateSetting(
      comboTrainerKey, value, () => _comboTrainerEnabled = value, _comboTrainerEnabled);

  Future<void> setComboUseNames(bool value) => _updateSetting(
      comboUseNamesKey, value, () => _comboUseNames = value, _comboUseNames);

  Future<void> _updateSetting<T>(
    String key,
    T value,
    void Function() updateState,
    T currentValue,
  ) async {
    if (currentValue == value) return;
    updateState();
    notifyListeners();
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }
}
