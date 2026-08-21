// Port of LanguageManager.swift — all translations for the 7 supported
// languages. Every user-facing string in the app comes from [Translations].

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Die 7 unterstützten Sprachen (Port von AppLanguage in LanguageManager.swift).
enum AppLanguage {
  de,
  en,
  ar,
  es,
  fr,
  ru,
  pt;

  /// Language code as persisted (matches the iOS rawValue).
  String get code => name;

  /// Display name with flag emoji, exactly as on iOS.
  String get displayName {
    switch (this) {
      case AppLanguage.de:
        return '🇩🇪 Deutsch';
      case AppLanguage.en:
        return '🇬🇧 English';
      case AppLanguage.ar:
        return '🇸🇦 العربية';
      case AppLanguage.es:
        return '🇪🇸 Español';
      case AppLanguage.fr:
        return '🇫🇷 Français';
      case AppLanguage.ru:
        return '🇷🇺 Русский';
      case AppLanguage.pt:
        return '🇵🇹 Português';
    }
  }

  /// Arabisch liest von rechts nach links.
  bool get isRtl => this == AppLanguage.ar;

  static AppLanguage? fromCode(String code) {
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// Speichert die gewählte Sprache und stellt Übersetzungen bereit.
class LanguageManager extends ChangeNotifier {
  static const String _prefsKey = 'appLanguage';

  final SharedPreferences _prefs;
  AppLanguage current;

  LanguageManager(this._prefs) : current = _deviceDefault() {
    final saved = _prefs.getString(_prefsKey);
    if (saved != null) {
      final language = AppLanguage.fromCode(saved);
      if (language != null) {
        current = language;
      }
    }
  }

  static AppLanguage _deviceDefault() {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    return AppLanguage.fromCode(deviceCode) ?? AppLanguage.en;
  }

  /// Kurzform: lang.t.xxx
  Translations get t => Translations.all[current]!;

  Future<void> setLanguage(AppLanguage language) async {
    current = language;
    notifyListeners();
    await _prefs.setString(_prefsKey, language.code);
  }

  /// Übersetzt den internen Preset-Namen in die gewählte Sprache.
  String localizedPresetName(String name) => t.localizedPresetName(name);
}

/// Alle Texte der App in einer Struktur (1:1 Port der Swift-Struktur Translations).
class Translations {
  // Timer-Phasen
  final String phaseWarmUp;
  final String phaseRest;
  final String phaseCoolDown;
  final String phaseFinished;
  final String phaseWork;
  final String phaseRound;

  // Tab-Leiste
  final String tabFightTimer;
  final String tabIntervals;
  final String tabHistory;
  final String tabStats;
  final String tabSettings;
  final String tabStopwatch;
  final String tabTodos;

  // Achievements & Heatmap
  final String heatmapTitle;
  final String heatmapLess;
  final String heatmapMore;
  final String heatmapUnit;
  final String achievementsTitle;
  final String notes;
  final String saveNotes;

  // Achievements
  final String achievementWarriorTitle;
  final String achievementWarriorDesc;
  final String achievementHardWorkerTitle;
  final String achievementHardWorkerDesc;
  final String achievementProFighterTitle;
  final String achievementProFighterDesc;

  // Fight Timer
  final String fightTimerTitle;
  final String chooseTimer;
  final String standardPresets;
  final String customProfiles;
  final String customizations;
  final String warmUp;
  final String rounds;
  final String roundTime;
  final String rest;
  final String cancel;
  final String done;
  final String newProfile;
  final String profileNameHint;
  final String save;

  // Interval Timer
  final String intervalTitle;
  final String chooseTraining;
  final String preset;
  final String customSetting;
  final String device;
  final String level;
  final String yourTraining;
  final String intervals;
  final String coolDown;
  final String totalApprox;
  final String startTraining;
  final String work;
  final String back;
  final String saveWorkout;
  final String saved;
  final String saveError;

  // Kampfsport-Namen (nur die, die sich wirklich ändern)
  final String sportBoxen;
  final String sportRingen;

  // IntervalDevice Namen
  final String deviceRunning;
  final String deviceTreadmill;
  final String deviceAirBike;
  final String deviceBagWork;

  // IntervalLevel Namen
  final String levelBeginner;
  final String levelIntermediate;
  final String levelAdvanced;

  // History
  final String historyTitle;
  final String noWorkouts;
  final String noWorkoutsDesc;
  final String deleteAll;
  final String confirmDeleteAll;
  final String workoutDetails;
  final String general;
  final String sport;
  final String mode;
  final String date;
  final String duration;
  final String fightTimerDetails;
  final String intervalDetails;

  // Statistiken
  final String statsTitle;
  final String thisWeek;
  final String totalTime;
  final String favoriteSport;
  final String streak;
  final String workoutsLabel;

  // Einstellungen
  final String settingsTitle;
  final String audioHaptic;
  final String soundEnabled;
  final String vibrationEnabled;
  final String warningEnabled;
  final String comboTrainer;
  final String comboInterval;
  final String language;
  final String about;
  final String version;
  final String developer;
  final String presetsInfo;
  final String ok;
  final String feedbackButton;
  final String rateApp;
  final String privacyPolicy;

  // Onboarding
  final String onboardingNext;
  final String onboardingStart;
  final String onboardingSkip;
  final String onboarding1Title;
  final String onboarding1Text;
  final String onboarding2Title;
  final String onboarding2Text;
  final String onboarding3Title;
  final String onboarding3Text;
  final String onboarding4Title;
  final String onboarding4Text;

  // Stoppuhr
  final String stopwatchTitle;
  final String stopwatchLap;
  final String stopwatchReset;
  final String stopwatchStart;
  final String stopwatchStop;
  final String stopwatchLaps;

  // Todos
  final String todosTitle;
  final String todoAdd;
  final String todoPlaceholder;
  final String todoOpen;
  final String todoDone;
  final String todoEmpty;
  final String todoEmptyDesc;
  final String todoNotifications;

  // Donation / Tip Jar
  final String donationTitle;
  final String donationSubtitle;
  final String donationSupport;
  final String donationThankYou;
  final String donationUnavailable;
  final String loading;
  final String retry;

  // Privacy Policy
  final String privacyNavTitle;
  final String privacyDate;
  final String privacySummary;
  final String privacyS1Title;
  final String privacyS1Text;
  final String privacyS2Title;
  final String privacyS2Text;
  final String privacyS3Title;
  final String privacyS3Text;
  final String privacyS4Title;
  final String privacyS4Text;
  final String privacyOpenBrowser;

  // Notification texts
  final String todoNotificationSingle;
  final String todoNotificationMultiple;

  const Translations({
    required this.phaseWarmUp,
    required this.phaseRest,
    required this.phaseCoolDown,
    required this.phaseFinished,
    required this.phaseWork,
    required this.phaseRound,
    required this.tabFightTimer,
    required this.tabIntervals,
    required this.tabHistory,
    required this.tabStats,
    required this.tabSettings,
    required this.tabStopwatch,
    required this.tabTodos,
    required this.heatmapTitle,
    required this.heatmapLess,
    required this.heatmapMore,
    required this.heatmapUnit,
    required this.achievementsTitle,
    required this.notes,
    required this.saveNotes,
    required this.achievementWarriorTitle,
    required this.achievementWarriorDesc,
    required this.achievementHardWorkerTitle,
    required this.achievementHardWorkerDesc,
    required this.achievementProFighterTitle,
    required this.achievementProFighterDesc,
    required this.fightTimerTitle,
    required this.chooseTimer,
    required this.standardPresets,
    required this.customProfiles,
    required this.customizations,
    required this.warmUp,
    required this.rounds,
    required this.roundTime,
    required this.rest,
    required this.cancel,
    required this.done,
    required this.newProfile,
    required this.profileNameHint,
    required this.save,
    required this.intervalTitle,
    required this.chooseTraining,
    required this.preset,
    required this.customSetting,
    required this.device,
    required this.level,
    required this.yourTraining,
    required this.intervals,
    required this.coolDown,
    required this.totalApprox,
    required this.startTraining,
    required this.work,
    required this.back,
    required this.saveWorkout,
    required this.saved,
    required this.saveError,
    required this.sportBoxen,
    required this.sportRingen,
    required this.deviceRunning,
    required this.deviceTreadmill,
    required this.deviceAirBike,
    required this.deviceBagWork,
    required this.levelBeginner,
    required this.levelIntermediate,
    required this.levelAdvanced,
    required this.historyTitle,
    required this.noWorkouts,
    required this.noWorkoutsDesc,
    required this.deleteAll,
    required this.confirmDeleteAll,
    required this.workoutDetails,
    required this.general,
    required this.sport,
    required this.mode,
    required this.date,
    required this.duration,
    required this.fightTimerDetails,
    required this.intervalDetails,
    required this.statsTitle,
    required this.thisWeek,
    required this.totalTime,
    required this.favoriteSport,
    required this.streak,
    required this.workoutsLabel,
    required this.settingsTitle,
    required this.audioHaptic,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.warningEnabled,
    required this.comboTrainer,
    required this.comboInterval,
    required this.language,
    required this.about,
    required this.version,
    required this.developer,
    required this.presetsInfo,
    required this.ok,
    required this.feedbackButton,
    required this.rateApp,
    required this.privacyPolicy,
    required this.onboardingNext,
    required this.onboardingStart,
    required this.onboardingSkip,
    required this.onboarding1Title,
    required this.onboarding1Text,
    required this.onboarding2Title,
    required this.onboarding2Text,
    required this.onboarding3Title,
    required this.onboarding3Text,
    required this.onboarding4Title,
    required this.onboarding4Text,
    required this.stopwatchTitle,
    required this.stopwatchLap,
    required this.stopwatchReset,
    required this.stopwatchStart,
    required this.stopwatchStop,
    required this.stopwatchLaps,
    required this.todosTitle,
    required this.todoAdd,
    required this.todoPlaceholder,
    required this.todoOpen,
    required this.todoDone,
    required this.todoEmpty,
    required this.todoEmptyDesc,
    required this.todoNotifications,
    required this.donationTitle,
    required this.donationSubtitle,
    required this.donationSupport,
    required this.donationThankYou,
    required this.donationUnavailable,
    required this.loading,
    required this.retry,
    required this.privacyNavTitle,
    required this.privacyDate,
    required this.privacySummary,
    required this.privacyS1Title,
    required this.privacyS1Text,
    required this.privacyS2Title,
    required this.privacyS2Text,
    required this.privacyS3Title,
    required this.privacyS3Text,
    required this.privacyS4Title,
    required this.privacyS4Text,
    required this.privacyOpenBrowser,
    required this.todoNotificationSingle,
    required this.todoNotificationMultiple,
  });

  /// Übersetzt den internen Preset-Namen in die gewählte Sprache.
  /// Für Fight Timer: nur Boxen und Ringen ändern sich – MMA, K1, Judo etc. bleiben gleich.
  /// Für Interval Timer: Geräte- und Level-Namen werden aus gespeicherten deutschen Rohwerten übersetzt.
  String localizedPresetName(String name) {
    // Fight Timer Presets
    if (name.contains('Boxen') || name.contains('Boxing')) {
      return '🥊 $sportBoxen';
    }
    if (name.contains('Ringen') || name.contains('Wrestling')) {
      return '🤼 $sportRingen';
    }
    // Interval Workout Namen: gespeicherte deutsche rawValues ersetzen
    var result = name;
    result = result.replaceAll('🏃 Draußen laufen', deviceRunning);
    result = result.replaceAll('🏋️ Laufband', deviceTreadmill);
    result = result.replaceAll('🚴 AirBike', deviceAirBike);
    result = result.replaceAll('🥊 Sandsack', deviceBagWork);
    result = result.replaceAll('Anfänger', levelBeginner);
    result = result.replaceAll('Fortgeschritten', levelIntermediate);
    result = result.replaceAll('Profi', levelAdvanced);
    return result;
  }

  // Alle Sprachen
  static final Map<AppLanguage, Translations> all = {
    AppLanguage.de: const Translations(
      phaseWarmUp: 'WARM UP',
      phaseRest: 'PAUSE',
      phaseCoolDown: 'COOL DOWN',
      phaseFinished: 'FERTIG!',
      phaseWork: 'WORK',
      phaseRound: 'RUNDE',
      tabFightTimer: 'Fight Timer',
      tabIntervals: 'Intervals',
      tabHistory: 'History',
      tabStats: 'Stats',
      tabSettings: 'Settings',
      tabStopwatch: 'Stoppuhr',
      tabTodos: 'Todos',
      heatmapTitle: 'Trainings-Heatmap',
      heatmapLess: 'weniger',
      heatmapMore: 'mehr',
      heatmapUnit: 'Min./Tag',
      achievementsTitle: 'Erfolge',
      notes: 'Notizen',
      saveNotes: 'Notizen speichern',
      achievementWarriorTitle: 'Kriegergeist',
      achievementWarriorDesc: '10 Tage Trainings-Serie',
      achievementHardWorkerTitle: 'Fleißiger Arbeiter',
      achievementHardWorkerDesc: '8 Stunden Gesamttraining',
      achievementProFighterTitle: 'Profi-Kämpfer',
      achievementProFighterDesc: 'Eine 12-Runden-Session beendet',
      fightTimerTitle: 'Fight Timer',
      chooseTimer: 'Timer wählen',
      standardPresets: 'Standard Presets',
      customProfiles: 'Custom Profile',
      customizations: 'Anpassungen',
      warmUp: 'Warm-up',
      rounds: 'Runden',
      roundTime: 'Rundenzeit',
      rest: 'Pause',
      cancel: 'Abbrechen',
      done: 'Fertig',
      newProfile: 'Neues Profil',
      profileNameHint: 'Profilname (z.B. Sambo)',
      save: 'Speichern',
      intervalTitle: 'Intervall Training',
      chooseTraining: 'Wähle dein Training',
      preset: 'Preset',
      customSetting: 'Eigene Einstellung',
      device: 'Gerät',
      level: 'Level',
      yourTraining: 'Dein Training:',
      intervals: 'Intervalle',
      coolDown: 'Cool-down',
      totalApprox: 'Gesamt: ca.',
      startTraining: 'Training starten',
      work: 'Work',
      back: 'Zurück',
      saveWorkout: 'Workout speichern',
      saved: 'Gespeichert!',
      saveError: 'Speichern fehlgeschlagen',
      sportBoxen: 'Boxen',
      sportRingen: 'Ringen',
      deviceRunning: '🏃 Draußen laufen',
      deviceTreadmill: '🏋️ Laufband',
      deviceAirBike: '🚴 AirBike',
      deviceBagWork: '🥊 Sandsack',
      levelBeginner: 'Anfänger',
      levelIntermediate: 'Fortgeschritten',
      levelAdvanced: 'Profi',
      historyTitle: 'Verlauf',
      noWorkouts: 'Keine Workouts',
      noWorkoutsDesc: 'Deine abgeschlossenen Workouts erscheinen hier',
      deleteAll: 'Alle löschen',
      confirmDeleteAll: 'Alle Workouts löschen?',
      workoutDetails: 'Workout Details',
      general: 'Allgemein',
      sport: 'Sportart',
      mode: 'Modus',
      date: 'Datum',
      duration: 'Dauer',
      fightTimerDetails: 'Fight Timer Details',
      intervalDetails: 'Interval Details',
      statsTitle: 'Statistiken',
      thisWeek: 'Diese Woche',
      totalTime: 'Gesamt Zeit',
      favoriteSport: 'Lieblings-Sport',
      streak: 'Streak',
      workoutsLabel: 'Workouts',
      settingsTitle: 'Einstellungen',
      audioHaptic: 'Audio & Haptik',
      soundEnabled: 'Sound aktiviert',
      vibrationEnabled: 'Vibration aktiviert',
      warningEnabled: '10-Sek. Warnsound',
      comboTrainer: 'Kombo-Trainer',
      comboInterval: 'Kombo-Intervall',
      language: 'Sprache',
      about: 'Über die App',
      version: 'Version',
      developer: 'Developer',
      presetsInfo: 'Presets Info',
      ok: 'OK',
      feedbackButton: 'Feedback senden',
      rateApp: 'App bewerten',
      privacyPolicy: 'Datenschutzerklärung',
      onboardingNext: 'Weiter',
      onboardingStart: "Los geht's!",
      onboardingSkip: 'Überspringen',
      onboarding1Title: 'Willkommen!',
      onboarding1Text: 'Dein professioneller Kampfsport-Timer für Training und Wettkampf.',
      onboarding2Title: 'Fight Timer',
      onboarding2Text: 'Presets für Boxen, MMA, K1, Muay Thai und mehr. Einfach auswählen und loslegen.',
      onboarding3Title: 'Interval Training',
      onboarding3Text: 'Intensives HIIT Training für Laufen, AirBike, Sandsack und mehr. Auch komplett anpassbar.',
      onboarding4Title: 'Fortschritt tracken',
      onboarding4Text: 'Alle Workouts werden gespeichert. Verfolge deinen Fortschritt in History und Statistiken.',
      stopwatchTitle: 'Stoppuhr',
      stopwatchLap: 'Runde',
      stopwatchReset: 'Reset',
      stopwatchStart: 'Start',
      stopwatchStop: 'Stop',
      stopwatchLaps: 'Runden',
      todosTitle: 'Meine Todos',
      todoAdd: 'Hinzufügen',
      todoPlaceholder: 'Neues Todo...',
      todoOpen: 'Offen',
      todoDone: 'Erledigt',
      todoEmpty: 'Keine Todos',
      todoEmptyDesc: 'Füge dein erstes Todo hinzu',
      todoNotifications: 'Todo-Erinnerungen',
      donationTitle: 'Entwickler unterstützen',
      donationSubtitle: 'Falls dir die App gefällt, freue ich mich über eine kleine Unterstützung 🙏',
      donationSupport: 'Unterstützen',
      donationThankYou: 'Vielen Dank! 🙏',
      donationUnavailable: 'Produkte nicht verfügbar.\nBitte Internetverbindung prüfen.',
      loading: 'Lädt...',
      retry: 'Erneut versuchen',
      privacyNavTitle: 'Datenschutzerklärung',
      privacyDate: 'Datenschutzerklärung · Februar 2026',
      privacySummary:
          'Diese App speichert keine persönlichen Daten, sendet keine Daten an Server und verwendet keine Tracker oder Werbung.',
      privacyS1Title: 'Welche Daten werden gespeichert?',
      privacyS1Text:
          'Nur lokal auf deinem Gerät:\n• Trainingshistorie (Datum, Dauer, Sportart)\n• App-Einstellungen (Sprache, Sound, Vibration)\n\nDiese Daten verlassen dein Gerät niemals.',
      privacyS2Title: 'Werden Daten übertragen?',
      privacyS2Text:
          'Nein. Die App sendet keine Daten an Server, verwendet keine Analyse-Tools und benötigt keine Internetverbindung.',
      privacyS3Title: 'In-App Käufe',
      privacyS3Text:
          'Optionale Donations werden vollständig über Google Play In-App Purchase abgewickelt. Wir haben keinen Zugriff auf Zahlungsdaten.',
      privacyS4Title: 'Berechtigungen',
      privacyS4Text:
          'Nur Live Activity (Timer auf dem Sperrbildschirm, optional). Keine anderen Berechtigungen.',
      privacyOpenBrowser: 'Vollständige Version im Browser öffnen',
      todoNotificationSingle: 'Du hast noch 1 offenes Todo!',
      todoNotificationMultiple: 'Du hast noch %d offene Todos!',
    ),
    AppLanguage.en: const Translations(
      phaseWarmUp: 'WARM UP',
      phaseRest: 'REST',
      phaseCoolDown: 'COOL DOWN',
      phaseFinished: 'DONE!',
      phaseWork: 'WORK',
      phaseRound: 'ROUND',
      tabFightTimer: 'Fight Timer',
      tabIntervals: 'Intervals',
      tabHistory: 'History',
      tabStats: 'Stats',
      tabSettings: 'Settings',
      tabStopwatch: 'Stopwatch',
      tabTodos: 'Todos',
      heatmapTitle: 'Workout Heatmap',
      heatmapLess: 'less',
      heatmapMore: 'more',
      heatmapUnit: 'min/day',
      achievementsTitle: 'Achievements',
      notes: 'Notes',
      saveNotes: 'Save Notes',
      achievementWarriorTitle: 'Warrior Spirit',
      achievementWarriorDesc: '10 day workout streak',
      achievementHardWorkerTitle: 'Hard Worker',
      achievementHardWorkerDesc: '8 hours of total training',
      achievementProFighterTitle: 'Pro Fighter',
      achievementProFighterDesc: 'Complete a 12-round session',
      fightTimerTitle: 'Fight Timer',
      chooseTimer: 'Choose Timer',
      standardPresets: 'Standard Presets',
      customProfiles: 'Custom Profiles',
      customizations: 'Customizations',
      warmUp: 'Warm-up',
      rounds: 'Rounds',
      roundTime: 'Round Time',
      rest: 'Rest',
      cancel: 'Cancel',
      done: 'Done',
      newProfile: 'New Profile',
      profileNameHint: 'Profile name (e.g. Sambo)',
      save: 'Save',
      intervalTitle: 'Interval Training',
      chooseTraining: 'Choose your training',
      preset: 'Preset',
      customSetting: 'Custom',
      device: 'Device',
      level: 'Level',
      yourTraining: 'Your training:',
      intervals: 'Intervals',
      coolDown: 'Cool-down',
      totalApprox: 'Total: approx.',
      startTraining: 'Start Training',
      work: 'Work',
      back: 'Back',
      saveWorkout: 'Save Workout',
      saved: 'Saved!',
      saveError: 'Save failed',
      sportBoxen: 'Boxing',
      sportRingen: 'Wrestling',
      deviceRunning: '🏃 Outdoor Running',
      deviceTreadmill: '🏋️ Treadmill',
      deviceAirBike: '🚴 Air Bike',
      deviceBagWork: '🥊 Bag Work',
      levelBeginner: 'Beginner',
      levelIntermediate: 'Intermediate',
      levelAdvanced: 'Advanced',
      historyTitle: 'History',
      noWorkouts: 'No Workouts',
      noWorkoutsDesc: 'Your completed workouts will appear here',
      deleteAll: 'Delete All',
      confirmDeleteAll: 'Delete all workouts?',
      workoutDetails: 'Workout Details',
      general: 'General',
      sport: 'Sport',
      mode: 'Mode',
      date: 'Date',
      duration: 'Duration',
      fightTimerDetails: 'Fight Timer Details',
      intervalDetails: 'Interval Details',
      statsTitle: 'Statistics',
      thisWeek: 'This Week',
      totalTime: 'Total Time',
      favoriteSport: 'Favorite Sport',
      streak: 'Streak',
      workoutsLabel: 'Workouts',
      settingsTitle: 'Settings',
      audioHaptic: 'Audio & Haptics',
      soundEnabled: 'Sound enabled',
      vibrationEnabled: 'Vibration enabled',
      warningEnabled: '10-sec. warning sound',
      comboTrainer: 'Combo Trainer',
      comboInterval: 'Combo interval',
      language: 'Language',
      about: 'About',
      version: 'Version',
      developer: 'Developer',
      presetsInfo: 'Presets Info',
      ok: 'OK',
      feedbackButton: 'Send Feedback',
      rateApp: 'Rate App',
      privacyPolicy: 'Privacy Policy',
      onboardingNext: 'Next',
      onboardingStart: "Let's Go!",
      onboardingSkip: 'Skip',
      onboarding1Title: 'Welcome!',
      onboarding1Text: 'Your professional combat sports timer for training and competition.',
      onboarding2Title: 'Fight Timer',
      onboarding2Text: 'Presets for Boxing, MMA, K1, Muay Thai and more. Just select and start.',
      onboarding3Title: 'Interval Training',
      onboarding3Text: 'Intense HIIT training for running, air bike, bag work and more. Fully customizable.',
      onboarding4Title: 'Track Progress',
      onboarding4Text: 'All workouts are saved. Follow your progress in History and Statistics.',
      stopwatchTitle: 'Stopwatch',
      stopwatchLap: 'Lap',
      stopwatchReset: 'Reset',
      stopwatchStart: 'Start',
      stopwatchStop: 'Stop',
      stopwatchLaps: 'Laps',
      todosTitle: 'My Todos',
      todoAdd: 'Add',
      todoPlaceholder: 'New todo...',
      todoOpen: 'Open',
      todoDone: 'Done',
      todoEmpty: 'No Todos',
      todoEmptyDesc: 'Add your first todo',
      todoNotifications: 'Todo Reminders',
      donationTitle: 'Support the Developer',
      donationSubtitle: "If you enjoy the app, I'd appreciate your support 🙏",
      donationSupport: 'Support',
      donationThankYou: 'Thank you so much! 🙏',
      donationUnavailable: 'Products not available.\nPlease check your internet connection.',
      loading: 'Loading...',
      retry: 'Try Again',
      privacyNavTitle: 'Privacy Policy',
      privacyDate: 'Privacy Policy · February 2026',
      privacySummary:
          'This app stores no personal data, sends no data to servers, and uses no trackers or advertising.',
      privacyS1Title: 'What data is stored?',
      privacyS1Text:
          'Only locally on your device:\n• Workout history (date, duration, sport)\n• App settings (language, sound, vibration)\n\nThis data never leaves your device.',
      privacyS2Title: 'Is data transmitted?',
      privacyS2Text:
          'No. The app sends no data to servers, uses no analytics tools, and requires no internet connection.',
      privacyS3Title: 'In-App Purchases',
      privacyS3Text:
          'Optional donations are handled entirely through Google Play In-App Purchase. We have no access to payment data.',
      privacyS4Title: 'Permissions',
      privacyS4Text: 'Only Live Activity (timer on the lock screen, optional). No other permissions.',
      privacyOpenBrowser: 'Open full version in browser',
      todoNotificationSingle: 'You have 1 open todo!',
      todoNotificationMultiple: 'You have %d open todos!',
    ),
    AppLanguage.ar: const Translations(
      phaseWarmUp: 'إحماء',
      phaseRest: 'راحة',
      phaseCoolDown: 'تبريد',
      phaseFinished: '!انتهى',
      phaseWork: 'تمرين',
      phaseRound: 'جولة',
      tabFightTimer: 'مؤقت القتال',
      tabIntervals: 'فترات',
      tabHistory: 'السجل',
      tabStats: 'إحصاءات',
      tabSettings: 'إعدادات',
      tabStopwatch: 'ساعة الإيقاف',
      tabTodos: 'المهام',
      heatmapTitle: 'مخطط التدريب',
      heatmapLess: 'أقل',
      heatmapMore: 'أكثر',
      heatmapUnit: 'دقيقة/يوم',
      achievementsTitle: 'الإنجازات',
      notes: 'ملاحظات',
      saveNotes: 'حفظ الملاحظات',
      achievementWarriorTitle: 'روح المحارب',
      achievementWarriorDesc: 'سلسلة تمارين لمدة 10 أيام',
      achievementHardWorkerTitle: 'عامل مجد',
      achievementHardWorkerDesc: '8 ساعات من التدريب الإجمالي',
      achievementProFighterTitle: 'مقاتل محترف',
      achievementProFighterDesc: 'أكمل جلسة من 12 جولة',
      fightTimerTitle: 'مؤقت القتال',
      chooseTimer: 'اختر المؤقت',
      standardPresets: 'الإعدادات الافتراضية',
      customProfiles: 'ملفات مخصصة',
      customizations: 'تخصيصات',
      warmUp: 'إحماء',
      rounds: 'جولات',
      roundTime: 'وقت الجولة',
      rest: 'راحة',
      cancel: 'إلغاء',
      done: 'تم',
      newProfile: 'ملف جديد',
      profileNameHint: 'اسم الملف (مثال: سامبو)',
      save: 'حفظ',
      intervalTitle: 'تدريب الفترات',
      chooseTraining: 'اختر تدريبك',
      preset: 'مُعد مسبقاً',
      customSetting: 'مخصص',
      device: 'الجهاز',
      level: 'المستوى',
      yourTraining: ':تدريبك',
      intervals: 'فترات',
      coolDown: 'تبريد',
      totalApprox: 'المجموع: تقريباً',
      startTraining: 'ابدأ التدريب',
      work: 'تمرين',
      back: 'رجوع',
      saveWorkout: 'حفظ التمرين',
      saved: '!تم الحفظ',
      saveError: 'فشل الحفظ',
      sportBoxen: 'ملاكمة',
      sportRingen: 'مصارعة',
      deviceRunning: '🏃 الجري الخارجي',
      deviceTreadmill: '🏋️ جهاز الجري',
      deviceAirBike: '🚴 دراجة هوائية',
      deviceBagWork: '🥊 كيس الملاكمة',
      levelBeginner: 'مبتدئ',
      levelIntermediate: 'متوسط',
      levelAdvanced: 'محترف',
      historyTitle: 'السجل',
      noWorkouts: 'لا توجد تمارين',
      noWorkoutsDesc: 'ستظهر هنا تمارينك المكتملة',
      deleteAll: 'حذف الكل',
      confirmDeleteAll: 'حذف جميع التمارين؟',
      workoutDetails: 'تفاصيل التمرين',
      general: 'عام',
      sport: 'الرياضة',
      mode: 'الوضع',
      date: 'التاريخ',
      duration: 'المدة',
      fightTimerDetails: 'تفاصيل مؤقت القتال',
      intervalDetails: 'تفاصيل الفترات',
      statsTitle: 'إحصاءات',
      thisWeek: 'هذا الأسبوع',
      totalTime: 'إجمالي الوقت',
      favoriteSport: 'الرياضة المفضلة',
      streak: 'تسلسل',
      workoutsLabel: 'تمارين',
      settingsTitle: 'إعدادات',
      audioHaptic: 'الصوت والاهتزاز',
      soundEnabled: 'تفعيل الصوت',
      vibrationEnabled: 'تفعيل الاهتزاز',
      warningEnabled: 'صوت تحذير 10 ثوانٍ',
      comboTrainer: 'مدرب التوليفات',
      comboInterval: 'الفاصل بين التوليفات',
      language: 'اللغة',
      about: 'عن التطبيق',
      version: 'الإصدار',
      developer: 'المطور',
      presetsInfo: 'معلومات الإعدادات',
      ok: 'موافق',
      feedbackButton: 'إرسال ملاحظات',
      rateApp: 'تقييم التطبيق',
      privacyPolicy: 'سياسة الخصوصية',
      onboardingNext: 'التالي',
      onboardingStart: 'هيا نبدأ!',
      onboardingSkip: 'تخطي',
      onboarding1Title: '!مرحباً',
      onboarding1Text: 'مؤقتك الاحترافي للرياضات القتالية للتدريب والمنافسة.',
      onboarding2Title: 'مؤقت القتال',
      onboarding2Text: 'إعدادات مسبقة للملاكمة وMMA وK1 والمواي تاي والمزيد.',
      onboarding3Title: 'تدريب الفترات',
      onboarding3Text: 'تدريب HIIT مكثف للجري والدراجة الهوائية وكيس الملاكمة والمزيد.',
      onboarding4Title: 'تتبع التقدم',
      onboarding4Text: 'يتم حفظ جميع التمارين. تابع تقدمك في السجل والإحصاءات.',
      stopwatchTitle: 'ساعة إيقاف',
      stopwatchLap: 'دورة',
      stopwatchReset: 'إعادة',
      stopwatchStart: 'ابدأ',
      stopwatchStop: 'وقف',
      stopwatchLaps: 'الدورات',
      todosTitle: 'مهامي',
      todoAdd: 'إضافة',
      todoPlaceholder: 'مهمة جديدة...',
      todoOpen: 'مفتوح',
      todoDone: 'منجز',
      todoEmpty: 'لا توجد مهام',
      todoEmptyDesc: 'أضف مهمتك الأولى',
      todoNotifications: 'تذكيرات المهام',
      donationTitle: 'دعم المطور',
      donationSubtitle: 'إذا أعجبك التطبيق، يسعدني دعمك 🙏',
      donationSupport: 'دعم',
      donationThankYou: 'شكراً جزيلاً! 🙏',
      donationUnavailable: 'المنتجات غير متاحة.\nيرجى التحقق من الاتصال بالإنترنت.',
      loading: 'جاري التحميل...',
      retry: 'حاول مجدداً',
      privacyNavTitle: 'سياسة الخصوصية',
      privacyDate: 'سياسة الخصوصية · فبراير 2026',
      privacySummary:
          'لا تخزّن هذه التطبيقة أي بيانات شخصية، ولا ترسل بيانات إلى خوادم، ولا تستخدم أدوات تتبع أو إعلانات.',
      privacyS1Title: 'ما البيانات التي يتم تخزينها؟',
      privacyS1Text:
          'محلياً على جهازك فقط:\n• سجل التمارين (التاريخ، المدة، الرياضة)\n• إعدادات التطبيق (اللغة، الصوت، الاهتزاز)\n\nهذه البيانات لا تغادر جهازك أبداً.',
      privacyS2Title: 'هل يتم نقل البيانات؟',
      privacyS2Text:
          'لا. لا ترسل التطبيقة بيانات إلى خوادم، ولا تستخدم أدوات تحليل، ولا تحتاج إلى اتصال بالإنترنت.',
      privacyS3Title: 'المشتريات داخل التطبيق',
      privacyS3Text:
          'تُعالَج التبرعات الاختيارية بالكامل عبر نظام Google Play للشراء داخل التطبيق. ليس لدينا أي وصول إلى بيانات الدفع.',
      privacyS4Title: 'الأذونات',
      privacyS4Text: 'فقط Live Activity (المؤقت على شاشة القفل، اختياري). لا توجد أذونات أخرى.',
      privacyOpenBrowser: 'فتح النسخة الكاملة في المتصفح',
      todoNotificationSingle: 'لديك مهمة واحدة مفتوحة!',
      todoNotificationMultiple: 'لديك %d مهام مفتوحة!',
    ),
    AppLanguage.es: const Translations(
      phaseWarmUp: 'CALENTAMIENTO',
      phaseRest: 'DESCANSO',
      phaseCoolDown: 'ENFRIAMIENTO',
      phaseFinished: '¡LISTO!',
      phaseWork: 'TRABAJO',
      phaseRound: 'RONDA',
      tabFightTimer: 'Cronómetro',
      tabIntervals: 'Intervalos',
      tabHistory: 'Historial',
      tabStats: 'Estadísticas',
      tabSettings: 'Ajustes',
      tabStopwatch: 'Cronómetro',
      tabTodos: 'Tareas',
      heatmapTitle: 'Mapa de calor',
      heatmapLess: 'menos',
      heatmapMore: 'más',
      heatmapUnit: 'min/día',
      achievementsTitle: 'Logros',
      notes: 'Notas',
      saveNotes: 'Guardar notas',
      achievementWarriorTitle: 'Espíritu Guerrero',
      achievementWarriorDesc: 'Racha de 10 días de entrenamiento',
      achievementHardWorkerTitle: 'Trabajador Incansable',
      achievementHardWorkerDesc: '8 horas de entrenamiento total',
      achievementProFighterTitle: 'Luchador Pro',
      achievementProFighterDesc: 'Completar una sesión de 12 rondas',
      fightTimerTitle: 'Cronómetro',
      chooseTimer: 'Elegir Cronómetro',
      standardPresets: 'Ajustes Estándar',
      customProfiles: 'Perfiles Personalizados',
      customizations: 'Personalizaciones',
      warmUp: 'Calentamiento',
      rounds: 'Rondas',
      roundTime: 'Tiempo de Ronda',
      rest: 'Descanso',
      cancel: 'Cancelar',
      done: 'Listo',
      newProfile: 'Nuevo Perfil',
      profileNameHint: 'Nombre del perfil (ej. Sambo)',
      save: 'Guardar',
      intervalTitle: 'Entrenamiento por Intervalos',
      chooseTraining: 'Elige tu entrenamiento',
      preset: 'Predefinido',
      customSetting: 'Personalizado',
      device: 'Equipo',
      level: 'Nivel',
      yourTraining: 'Tu entrenamiento:',
      intervals: 'Intervalos',
      coolDown: 'Enfriamiento',
      totalApprox: 'Total: aprox.',
      startTraining: 'Iniciar Entrenamiento',
      work: 'Trabajo',
      back: 'Atrás',
      saveWorkout: 'Guardar Entrenamiento',
      saved: '¡Guardado!',
      saveError: 'Error al guardar',
      sportBoxen: 'Boxeo',
      sportRingen: 'Lucha',
      deviceRunning: '🏃 Correr al aire libre',
      deviceTreadmill: '🏋️ Cinta de correr',
      deviceAirBike: '🚴 Bicicleta Air',
      deviceBagWork: '🥊 Saco de boxeo',
      levelBeginner: 'Principiante',
      levelIntermediate: 'Intermedio',
      levelAdvanced: 'Avanzado',
      historyTitle: 'Historial',
      noWorkouts: 'Sin Entrenamientos',
      noWorkoutsDesc: 'Tus entrenamientos completados aparecerán aquí',
      deleteAll: 'Eliminar Todo',
      confirmDeleteAll: '¿Eliminar todos los entrenamientos?',
      workoutDetails: 'Detalles del Entrenamiento',
      general: 'General',
      sport: 'Deporte',
      mode: 'Modo',
      date: 'Fecha',
      duration: 'Duración',
      fightTimerDetails: 'Detalles del Cronómetro',
      intervalDetails: 'Detalles de Intervalos',
      statsTitle: 'Estadísticas',
      thisWeek: 'Esta Semana',
      totalTime: 'Tiempo Total',
      favoriteSport: 'Deporte Favorito',
      streak: 'Racha',
      workoutsLabel: 'Entrenamientos',
      settingsTitle: 'Ajustes',
      audioHaptic: 'Audio y Háptico',
      soundEnabled: 'Sonido activado',
      vibrationEnabled: 'Vibración activada',
      warningEnabled: 'Sonido de aviso 10 seg.',
      comboTrainer: 'Entrenador de combos',
      comboInterval: 'Intervalo de combos',
      language: 'Idioma',
      about: 'Acerca de',
      version: 'Versión',
      developer: 'Desarrollador',
      presetsInfo: 'Info de Presets',
      ok: 'OK',
      feedbackButton: 'Enviar comentarios',
      rateApp: 'Valorar la app',
      privacyPolicy: 'Política de privacidad',
      onboardingNext: 'Siguiente',
      onboardingStart: '¡Vamos!',
      onboardingSkip: 'Omitir',
      onboarding1Title: '¡Bienvenido!',
      onboarding1Text: 'Tu temporizador profesional de deportes de combate para entrenamiento y competición.',
      onboarding2Title: 'Cronómetro',
      onboarding2Text: 'Ajustes para Boxeo, MMA, K1, Muay Thai y más. Solo selecciona y empieza.',
      onboarding3Title: 'Entrenamiento por Intervalos',
      onboarding3Text:
          'Entrenamiento HIIT intenso para correr, bicicleta y saco de boxeo. Totalmente personalizable.',
      onboarding4Title: 'Seguir el Progreso',
      onboarding4Text: 'Todos los entrenamientos se guardan. Sigue tu progreso en Historial y Estadísticas.',
      stopwatchTitle: 'Cronómetro',
      stopwatchLap: 'Vuelta',
      stopwatchReset: 'Reiniciar',
      stopwatchStart: 'Iniciar',
      stopwatchStop: 'Parar',
      stopwatchLaps: 'Vueltas',
      todosTitle: 'Mis Tareas',
      todoAdd: 'Añadir',
      todoPlaceholder: 'Nueva tarea...',
      todoOpen: 'Pendiente',
      todoDone: 'Hecho',
      todoEmpty: 'Sin tareas',
      todoEmptyDesc: 'Añade tu primera tarea',
      todoNotifications: 'Recordatorios de tareas',
      donationTitle: 'Apoya al Desarrollador',
      donationSubtitle: 'Si disfrutas la app, agradeceré tu apoyo 🙏',
      donationSupport: 'Apoyar',
      donationThankYou: '¡Muchas gracias! 🙏',
      donationUnavailable: 'Productos no disponibles.\nComprueba tu conexión a internet.',
      loading: 'Cargando...',
      retry: 'Reintentar',
      privacyNavTitle: 'Política de privacidad',
      privacyDate: 'Política de privacidad · Febrero 2026',
      privacySummary:
          'Esta app no almacena datos personales, no envía datos a servidores y no utiliza rastreadores ni publicidad.',
      privacyS1Title: '¿Qué datos se almacenan?',
      privacyS1Text:
          'Solo localmente en tu dispositivo:\n• Historial de entrenamientos (fecha, duración, deporte)\n• Configuración de la app (idioma, sonido, vibración)\n\nEstos datos nunca salen de tu dispositivo.',
      privacyS2Title: '¿Se transmiten datos?',
      privacyS2Text:
          'No. La app no envía datos a servidores, no utiliza herramientas de análisis y no requiere conexión a internet.',
      privacyS3Title: 'Compras dentro de la app',
      privacyS3Text:
          'Las donaciones opcionales se gestionan completamente a través de Google Play In-App Purchase. No tenemos acceso a datos de pago.',
      privacyS4Title: 'Permisos',
      privacyS4Text:
          'Solo Live Activity (temporizador en la pantalla de bloqueo, opcional). Sin otros permisos.',
      privacyOpenBrowser: 'Abrir versión completa en el navegador',
      todoNotificationSingle: '¡Tienes 1 tarea pendiente!',
      todoNotificationMultiple: '¡Tienes %d tareas pendientes!',
    ),
    AppLanguage.fr: const Translations(
      phaseWarmUp: 'ÉCHAUFFEMENT',
      phaseRest: 'REPOS',
      phaseCoolDown: 'RÉCUPÉRATION',
      phaseFinished: 'TERMINÉ!',
      phaseWork: 'TRAVAIL',
      phaseRound: 'ROUND',
      tabFightTimer: 'Chrono Combat',
      tabIntervals: 'Intervalles',
      tabHistory: 'Historique',
      tabStats: 'Statistiques',
      tabSettings: 'Réglages',
      tabStopwatch: 'Chronomètre',
      tabTodos: 'Tâches',
      heatmapTitle: 'Carte thermique',
      heatmapLess: 'moins',
      heatmapMore: 'plus',
      heatmapUnit: 'min/jour',
      achievementsTitle: 'Succès',
      notes: 'Notes',
      saveNotes: 'Enregistrer les notes',
      achievementWarriorTitle: 'Esprit Guerrier',
      achievementWarriorDesc: "Série de 10 jours d'entraînement",
      achievementHardWorkerTitle: 'Travailleur Acharné',
      achievementHardWorkerDesc: "8 heures d'entraînement total",
      achievementProFighterTitle: 'Combattant Pro',
      achievementProFighterDesc: 'Terminer une séance de 12 rounds',
      fightTimerTitle: 'Chrono Combat',
      chooseTimer: 'Choisir le Chrono',
      standardPresets: 'Préréglages Standards',
      customProfiles: 'Profils Personnalisés',
      customizations: 'Personnalisations',
      warmUp: 'Échauffement',
      rounds: 'Rounds',
      roundTime: 'Durée du Round',
      rest: 'Repos',
      cancel: 'Annuler',
      done: 'Terminer',
      newProfile: 'Nouveau Profil',
      profileNameHint: 'Nom du profil (ex. Sambo)',
      save: 'Enregistrer',
      intervalTitle: 'Entraînement par Intervalles',
      chooseTraining: 'Choisissez votre entraînement',
      preset: 'Préréglage',
      customSetting: 'Personnalisé',
      device: 'Appareil',
      level: 'Niveau',
      yourTraining: 'Votre entraînement :',
      intervals: 'Intervalles',
      coolDown: 'Récupération',
      totalApprox: 'Total : environ',
      startTraining: "Démarrer l'Entraînement",
      work: 'Travail',
      back: 'Retour',
      saveWorkout: "Enregistrer l'entraînement",
      saved: 'Enregistré !',
      saveError: "Échec de l'enregistrement",
      sportBoxen: 'Boxe',
      sportRingen: 'Lutte',
      deviceRunning: '🏃 Course en plein air',
      deviceTreadmill: '🏋️ Tapis de course',
      deviceAirBike: '🚴 Vélo Air',
      deviceBagWork: '🥊 Sac de frappe',
      levelBeginner: 'Débutant',
      levelIntermediate: 'Intermédiaire',
      levelAdvanced: 'Avancé',
      historyTitle: 'Historique',
      noWorkouts: 'Aucun entraînement',
      noWorkoutsDesc: 'Vos entraînements terminés apparaîtront ici',
      deleteAll: 'Tout supprimer',
      confirmDeleteAll: 'Supprimer tous les entraînements ?',
      workoutDetails: "Détails de l'entraînement",
      general: 'Général',
      sport: 'Sport',
      mode: 'Mode',
      date: 'Date',
      duration: 'Durée',
      fightTimerDetails: 'Détails du Chrono',
      intervalDetails: 'Détails des Intervalles',
      statsTitle: 'Statistiques',
      thisWeek: 'Cette Semaine',
      totalTime: 'Temps Total',
      favoriteSport: 'Sport Favori',
      streak: 'Série',
      workoutsLabel: 'Entraînements',
      settingsTitle: 'Réglages',
      audioHaptic: 'Audio & Haptique',
      soundEnabled: 'Son activé',
      vibrationEnabled: 'Vibration activée',
      warningEnabled: "Son d'avertissement 10 sec.",
      comboTrainer: 'Entraîneur de combos',
      comboInterval: 'Intervalle des combos',
      language: 'Langue',
      about: 'À propos',
      version: 'Version',
      developer: 'Développeur',
      presetsInfo: 'Info Préréglages',
      ok: 'OK',
      feedbackButton: 'Envoyer un avis',
      rateApp: "Noter l'app",
      privacyPolicy: 'Politique de confidentialité',
      onboardingNext: 'Suivant',
      onboardingStart: "C'est parti!",
      onboardingSkip: 'Passer',
      onboarding1Title: 'Bienvenue!',
      onboarding1Text:
          "Votre minuteur professionnel de sports de combat pour l'entraînement et la compétition.",
      onboarding2Title: 'Chrono Combat',
      onboarding2Text: 'Préréglages pour Boxe, MMA, K1, Muay Thai et plus. Sélectionnez et démarrez.',
      onboarding3Title: 'Entraînement Intervalles',
      onboarding3Text:
          'Entraînement HIIT intense pour course, vélo et sac de frappe. Entièrement personnalisable.',
      onboarding4Title: 'Suivre la Progression',
      onboarding4Text:
          'Tous les entraînements sont sauvegardés. Suivez votre progression dans Historique et Statistiques.',
      stopwatchTitle: 'Chronomètre',
      stopwatchLap: 'Tour',
      stopwatchReset: 'Réinitialiser',
      stopwatchStart: 'Démarrer',
      stopwatchStop: 'Arrêter',
      stopwatchLaps: 'Tours',
      todosTitle: 'Mes Tâches',
      todoAdd: 'Ajouter',
      todoPlaceholder: 'Nouvelle tâche...',
      todoOpen: 'En cours',
      todoDone: 'Terminé',
      todoEmpty: 'Aucune tâche',
      todoEmptyDesc: 'Ajoutez votre première tâche',
      todoNotifications: 'Rappels de tâches',
      donationTitle: 'Soutenir le Développeur',
      donationSubtitle: "Si vous aimez l'app, j'apprécierais votre soutien 🙏",
      donationSupport: 'Soutenir',
      donationThankYou: 'Merci beaucoup ! 🙏',
      donationUnavailable: 'Produits non disponibles.\nVérifiez votre connexion internet.',
      loading: 'Chargement...',
      retry: 'Réessayer',
      privacyNavTitle: 'Politique de confidentialité',
      privacyDate: 'Politique de confidentialité · Février 2026',
      privacySummary:
          "Cette app ne stocke aucune donnée personnelle, n'envoie pas de données à des serveurs et n'utilise aucun traceur ni publicité.",
      privacyS1Title: 'Quelles données sont stockées ?',
      privacyS1Text:
          "Uniquement en local sur votre appareil :\n• Historique d'entraînement (date, durée, sport)\n• Paramètres de l'app (langue, son, vibration)\n\nCes données ne quittent jamais votre appareil.",
      privacyS2Title: 'Des données sont-elles transmises ?',
      privacyS2Text:
          "Non. L'app n'envoie aucune donnée à des serveurs, n'utilise aucun outil d'analyse et ne nécessite aucune connexion internet.",
      privacyS3Title: 'Achats intégrés',
      privacyS3Text:
          "Les dons optionnels sont entièrement traités via Google Play In-App Purchase. Nous n'avons aucun accès aux données de paiement.",
      privacyS4Title: 'Autorisations',
      privacyS4Text:
          "Uniquement Live Activity (minuterie sur l'écran de verrouillage, optionnel). Aucune autre autorisation.",
      privacyOpenBrowser: 'Ouvrir la version complète dans le navigateur',
      todoNotificationSingle: 'Vous avez 1 tâche en cours !',
      todoNotificationMultiple: 'Vous avez %d tâches en cours !',
    ),
    AppLanguage.ru: const Translations(
      phaseWarmUp: 'РАЗМИНКА',
      phaseRest: 'ОТДЫХ',
      phaseCoolDown: 'ЗАМИНКА',
      phaseFinished: 'ГОТОВО!',
      phaseWork: 'РАБОТА',
      phaseRound: 'РАУНД',
      tabFightTimer: 'Таймер',
      tabIntervals: 'Интервалы',
      tabHistory: 'История',
      tabStats: 'Статистика',
      tabSettings: 'Настройки',
      tabStopwatch: 'Секундомер',
      tabTodos: 'Задачи',
      heatmapTitle: 'Активность',
      heatmapLess: 'меньше',
      heatmapMore: 'больше',
      heatmapUnit: 'мин/день',
      achievementsTitle: 'Достижения',
      notes: 'Заметки',
      saveNotes: 'Сохранить заметки',
      achievementWarriorTitle: 'Дух воина',
      achievementWarriorDesc: '10-дневная серия тренировок',
      achievementHardWorkerTitle: 'Трудоголик',
      achievementHardWorkerDesc: '8 часов тренировок всего',
      achievementProFighterTitle: 'Профи',
      achievementProFighterDesc: 'Завершить 12-раундовую сессию',
      fightTimerTitle: 'Таймер Боя',
      chooseTimer: 'Выбрать Таймер',
      standardPresets: 'Стандартные Пресеты',
      customProfiles: 'Свои Профили',
      customizations: 'Настройки',
      warmUp: 'Разминка',
      rounds: 'Раунды',
      roundTime: 'Время Раунда',
      rest: 'Отдых',
      cancel: 'Отмена',
      done: 'Готово',
      newProfile: 'Новый Профиль',
      profileNameHint: 'Название профиля (напр. Самбо)',
      save: 'Сохранить',
      intervalTitle: 'Интервальная Тренировка',
      chooseTraining: 'Выбери тренировку',
      preset: 'Пресет',
      customSetting: 'Свои настройки',
      device: 'Устройство',
      level: 'Уровень',
      yourTraining: 'Твоя тренировка:',
      intervals: 'Интервалы',
      coolDown: 'Заминка',
      totalApprox: 'Итого: прим.',
      startTraining: 'Начать тренировку',
      work: 'Работа',
      back: 'Назад',
      saveWorkout: 'Сохранить тренировку',
      saved: 'Сохранено!',
      saveError: 'Не удалось сохранить',
      sportBoxen: 'Бокс',
      sportRingen: 'Борьба',
      deviceRunning: '🏃 Бег на улице',
      deviceTreadmill: '🏋️ Беговая дорожка',
      deviceAirBike: '🚴 Велотренажёр',
      deviceBagWork: '🥊 Груша',
      levelBeginner: 'Начинающий',
      levelIntermediate: 'Средний',
      levelAdvanced: 'Продвинутый',
      historyTitle: 'История',
      noWorkouts: 'Нет тренировок',
      noWorkoutsDesc: 'Здесь появятся завершённые тренировки',
      deleteAll: 'Удалить всё',
      confirmDeleteAll: 'Удалить все тренировки?',
      workoutDetails: 'Детали тренировки',
      general: 'Общее',
      sport: 'Спорт',
      mode: 'Режим',
      date: 'Дата',
      duration: 'Длительность',
      fightTimerDetails: 'Детали таймера боя',
      intervalDetails: 'Детали интервалов',
      statsTitle: 'Статистика',
      thisWeek: 'На этой неделе',
      totalTime: 'Общее время',
      favoriteSport: 'Любимый спорт',
      streak: 'Серия',
      workoutsLabel: 'Тренировки',
      settingsTitle: 'Настройки',
      audioHaptic: 'Звук и вибрация',
      soundEnabled: 'Звук включён',
      vibrationEnabled: 'Вибрация включена',
      warningEnabled: 'Предупредительный звук 10 сек.',
      comboTrainer: 'Тренажёр комбинаций',
      comboInterval: 'Интервал комбинаций',
      language: 'Язык',
      about: 'О приложении',
      version: 'Версия',
      developer: 'Разработчик',
      presetsInfo: 'Информация о пресетах',
      ok: 'OK',
      feedbackButton: 'Отправить отзыв',
      rateApp: 'Оценить приложение',
      privacyPolicy: 'Политика конфиденциальности',
      onboardingNext: 'Далее',
      onboardingStart: 'Начнём!',
      onboardingSkip: 'Пропустить',
      onboarding1Title: 'Добро пожаловать!',
      onboarding1Text: 'Твой профессиональный таймер для боевых видов спорта.',
      onboarding2Title: 'Таймер Боя',
      onboarding2Text: 'Пресеты для бокса, MMA, K1, муай-тай и других видов спорта.',
      onboarding3Title: 'Интервальная Тренировка',
      onboarding3Text: 'Интенсивный HIIT для бега, велотренажёра, груши и многого другого.',
      onboarding4Title: 'Отслеживай Прогресс',
      onboarding4Text: 'Все тренировки сохраняются. Следи за прогрессом в истории и статистике.',
      stopwatchTitle: 'Секундомер',
      stopwatchLap: 'Круг',
      stopwatchReset: 'Сброс',
      stopwatchStart: 'Старт',
      stopwatchStop: 'Стоп',
      stopwatchLaps: 'Круги',
      todosTitle: 'Мои задачи',
      todoAdd: 'Добавить',
      todoPlaceholder: 'Новая задача...',
      todoOpen: 'Открытые',
      todoDone: 'Выполнено',
      todoEmpty: 'Нет задач',
      todoEmptyDesc: 'Добавьте первую задачу',
      todoNotifications: 'Напоминания о задачах',
      donationTitle: 'Поддержать разработчика',
      donationSubtitle: 'Если тебе нравится приложение, буду рад твоей поддержке 🙏',
      donationSupport: 'Поддержать',
      donationThankYou: 'Большое спасибо! 🙏',
      donationUnavailable: 'Продукты недоступны.\nПроверьте подключение к интернету.',
      loading: 'Загрузка...',
      retry: 'Повторить',
      privacyNavTitle: 'Политика конфиденциальности',
      privacyDate: 'Политика конфиденциальности · Февраль 2026',
      privacySummary:
          'Приложение не хранит личные данные, не отправляет данные на серверы и не использует трекеры или рекламу.',
      privacyS1Title: 'Какие данные хранятся?',
      privacyS1Text:
          'Только локально на вашем устройстве:\n• История тренировок (дата, длительность, вид спорта)\n• Настройки приложения (язык, звук, вибрация)\n\nЭти данные никогда не покидают ваше устройство.',
      privacyS2Title: 'Передаются ли данные?',
      privacyS2Text:
          'Нет. Приложение не отправляет данные на серверы, не использует инструменты аналитики и не требует подключения к интернету.',
      privacyS3Title: 'Встроенные покупки',
      privacyS3Text:
          'Необязательные пожертвования обрабатываются полностью через Google Play In-App Purchase. У нас нет доступа к платёжным данным.',
      privacyS4Title: 'Разрешения',
      privacyS4Text:
          'Только Live Activity (таймер на экране блокировки, опционально). Никаких других разрешений.',
      privacyOpenBrowser: 'Открыть полную версию в браузере',
      todoNotificationSingle: 'У вас 1 активная задача!',
      todoNotificationMultiple: 'У вас %d активных задач!',
    ),
    AppLanguage.pt: const Translations(
      phaseWarmUp: 'AQUECIMENTO',
      phaseRest: 'DESCANSO',
      phaseCoolDown: 'DESACELERAÇÃO',
      phaseFinished: 'CONCLUÍDO!',
      phaseWork: 'TRABALHO',
      phaseRound: 'ROUND',
      tabFightTimer: 'Timer de Luta',
      tabIntervals: 'Intervalos',
      tabHistory: 'Histórico',
      tabStats: 'Estatísticas',
      tabSettings: 'Ajustes',
      tabStopwatch: 'Cronômetro',
      tabTodos: 'Tarefas',
      heatmapTitle: 'Mapa de Calor',
      heatmapLess: 'menos',
      heatmapMore: 'mais',
      heatmapUnit: 'min/dia',
      achievementsTitle: 'Conquistas',
      notes: 'Notas',
      saveNotes: 'Salvar Notas',
      achievementWarriorTitle: 'Espírito Guerreiro',
      achievementWarriorDesc: 'Sequência de 10 dias de treino',
      achievementHardWorkerTitle: 'Trabalhador Árduo',
      achievementHardWorkerDesc: '8 horas de treino total',
      achievementProFighterTitle: 'Lutador Pro',
      achievementProFighterDesc: 'Concluir uma sessão de 12 rounds',
      fightTimerTitle: 'Timer de Luta',
      chooseTimer: 'Escolher Timer',
      standardPresets: 'Predefinições Padrão',
      customProfiles: 'Perfis Personalizados',
      customizations: 'Personalizações',
      warmUp: 'Aquecimento',
      rounds: 'Rounds',
      roundTime: 'Tempo de Round',
      rest: 'Descanso',
      cancel: 'Cancelar',
      done: 'Concluído',
      newProfile: 'Novo Perfil',
      profileNameHint: 'Nome do perfil (ex: Sambo)',
      save: 'Salvar',
      intervalTitle: 'Treino de Intervalos',
      chooseTraining: 'Escolha seu treino',
      preset: 'Predefinição',
      customSetting: 'Personalizado',
      device: 'Equipamento',
      level: 'Nível',
      yourTraining: 'Seu treino:',
      intervals: 'Intervalos',
      coolDown: 'Desaceleração',
      totalApprox: 'Total: aprox.',
      startTraining: 'Iniciar Treino',
      work: 'Trabalho',
      back: 'Voltar',
      saveWorkout: 'Salvar Treino',
      saved: 'Salvo!',
      saveError: 'Falha ao salvar',
      sportBoxen: 'Boxe',
      sportRingen: 'Luta Livre',
      deviceRunning: '🏃 Corrida ao ar livre',
      deviceTreadmill: '🏋️ Esteira',
      deviceAirBike: '🚴 Bicicleta Air',
      deviceBagWork: '🥊 Saco de pancadas',
      levelBeginner: 'Iniciante',
      levelIntermediate: 'Intermediário',
      levelAdvanced: 'Avançado',
      historyTitle: 'Histórico',
      noWorkouts: 'Sem Treinos',
      noWorkoutsDesc: 'Seus treinos concluídos aparecerão aqui',
      deleteAll: 'Excluir Tudo',
      confirmDeleteAll: 'Excluir todos os treinos?',
      workoutDetails: 'Detalhes do Treino',
      general: 'Geral',
      sport: 'Esporte',
      mode: 'Modo',
      date: 'Data',
      duration: 'Duração',
      fightTimerDetails: 'Detalhes do Timer de Luta',
      intervalDetails: 'Detalhes de Intervalos',
      statsTitle: 'Estatísticas',
      thisWeek: 'Esta Semana',
      totalTime: 'Tempo Total',
      favoriteSport: 'Esporte Favorito',
      streak: 'Sequência',
      workoutsLabel: 'Treinos',
      settingsTitle: 'Ajustes',
      audioHaptic: 'Áudio e Háptica',
      soundEnabled: 'Som ativado',
      vibrationEnabled: 'Vibração ativada',
      warningEnabled: 'Som de aviso 10 seg.',
      comboTrainer: 'Treinador de combos',
      comboInterval: 'Intervalo de combos',
      language: 'Idioma',
      about: 'Sobre',
      version: 'Versão',
      developer: 'Desenvolvedor',
      presetsInfo: 'Informação de Presets',
      ok: 'OK',
      feedbackButton: 'Enviar feedback',
      rateApp: 'Avaliar app',
      privacyPolicy: 'Política de Privacidade',
      onboardingNext: 'Próximo',
      onboardingStart: 'Vamos lá!',
      onboardingSkip: 'Pular',
      onboarding1Title: 'Bem-vindo!',
      onboarding1Text: 'Seu timer profissional de esportes de combate para treino e competição.',
      onboarding2Title: 'Timer de Luta',
      onboarding2Text: 'Predefinições para Boxe, MMA, K1, Muay Thai e mais. Basta selecionar e começar.',
      onboarding3Title: 'Treino de Intervalos',
      onboarding3Text:
          'Treino HIIT intenso para corrida, bicicleta, saco de pancadas e mais. Totalmente personalizável.',
      onboarding4Title: 'Acompanhar Progresso',
      onboarding4Text: 'Todos os treinos são salvos. Acompanhe seu progresso no Histórico e Estatísticas.',
      stopwatchTitle: 'Cronômetro',
      stopwatchLap: 'Volta',
      stopwatchReset: 'Resetar',
      stopwatchStart: 'Iniciar',
      stopwatchStop: 'Parar',
      stopwatchLaps: 'Voltas',
      todosTitle: 'Minhas Tarefas',
      todoAdd: 'Adicionar',
      todoPlaceholder: 'Nova tarefa...',
      todoOpen: 'Aberto',
      todoDone: 'Concluído',
      todoEmpty: 'Sem tarefas',
      todoEmptyDesc: 'Adicione sua primeira tarefa',
      todoNotifications: 'Lembretes de tarefas',
      donationTitle: 'Apoiar o Desenvolvedor',
      donationSubtitle: 'Se você gosta do app, eu agradeceria seu apoio 🙏',
      donationSupport: 'Apoiar',
      donationThankYou: 'Muito obrigado! 🙏',
      donationUnavailable: 'Produtos não disponíveis.\nVerifique sua conexão com a internet.',
      loading: 'Carregando...',
      retry: 'Tentar Novamente',
      privacyNavTitle: 'Política de Privacidade',
      privacyDate: 'Política de Privacidade · Fevereiro 2026',
      privacySummary:
          'Este aplicativo não armazena dados pessoais, não envia dados para servidores e não utiliza rastreadores ou publicidade.',
      privacyS1Title: 'Quais dados são armazenados?',
      privacyS1Text:
          'Apenas localmente no seu dispositivo:\n• Histórico de treinos (data, duração, esporte)\n• Ajustes do app (idioma, som, vibração)\n\nEstes dados nunca saem do seu dispositivo.',
      privacyS2Title: 'Os dados são transmitidos?',
      privacyS2Text:
          'Não. O aplicativo não envia dados para servidores, não utiliza ferramentas de análise e não requer conexão com a internet.',
      privacyS3Title: 'Compras no App',
      privacyS3Text:
          'Doações opcionais são processadas inteiramente através da Google Play In-App Purchase. Não temos acesso aos dados de pagamento.',
      privacyS4Title: 'Permissões',
      privacyS4Text: 'Apenas Live Activity (timer na tela de bloqueio, opcional). Sem outras permissões.',
      privacyOpenBrowser: 'Abrir versão completa no navegador',
      todoNotificationSingle: 'Você tem 1 tarefa aberta!',
      todoNotificationMultiple: 'Você tem %d tarefas abertas!',
    ),
  };
}
