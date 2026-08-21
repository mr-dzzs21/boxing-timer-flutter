import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port of the iOS `AppPromptManager` (AppPromptManager.swift).
///
/// Tracks the number of completed workouts and decides when the one-time
/// donation prompt should be shown (30 days after first launch).
/// Uses the same keys as iOS UserDefaults.
class PromptManager extends ChangeNotifier {
  PromptManager(this._prefs) {
    completedWorkoutsCount = _prefs.getInt(_workoutCountKey) ?? 0;

    // Record the first launch date once, like the iOS init.
    if (_prefs.getInt(_firstLaunchKey) == null) {
      _prefs.setInt(_firstLaunchKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  static const String _firstLaunchKey = 'firstLaunchDate';
  static const String _donationShownKey = 'donationPromptShown';
  static const String _workoutCountKey = 'completedWorkoutsCount';

  final SharedPreferences _prefs;

  int completedWorkoutsCount = 0;

  /// Called whenever a workout is saved to history.
  Future<void> recordWorkoutCompleted() async {
    completedWorkoutsCount += 1;
    notifyListeners();
    await _prefs.setInt(_workoutCountKey, completedWorkoutsCount);
  }

  /// True exactly once: 30+ days after first launch and never shown before.
  /// Marks the prompt as shown when it returns true (mirrors iOS
  /// `checkDonationPrompt`).
  bool get shouldShowDonationPrompt {
    if (_prefs.getBool(_donationShownKey) ?? false) return false;

    final firstLaunchMillis = _prefs.getInt(_firstLaunchKey);
    if (firstLaunchMillis == null) return false;

    final firstLaunch =
        DateTime.fromMillisecondsSinceEpoch(firstLaunchMillis);
    final days = DateTime.now().difference(firstLaunch).inDays;
    if (days >= 30) {
      _prefs.setBool(_donationShownKey, true);
      return true;
    }
    return false;
  }

  /// iOS parity: request an App Store review after 5, 15 or 30 workouts.
  bool get shouldRequestReview {
    final count = completedWorkoutsCount;
    return count == 5 || count == 15 || count == 30;
  }
}
