import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boxing_timer_flutter/core/models.dart';

/// Port of the iOS `ProfileManager` (ModelsAndStubs.swift).
///
/// Stores user-created fight presets as JSON in shared preferences under the
/// same key the iOS app uses in UserDefaults ('customProfiles').
class ProfileManager extends ChangeNotifier {
  static const String _prefsKey = 'customProfiles';

  List<FightPreset> customProfiles = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        customProfiles = decoded
            .whereType<Map<String, dynamic>>()
            .map(FightPreset.fromJson)
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileManager: could not load custom profiles: $e');
    }
  }

  Future<void> add(FightPreset preset) async {
    customProfiles = [...customProfiles, preset];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    customProfiles =
        customProfiles.where((profile) => profile.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(customProfiles.map((profile) => profile.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
