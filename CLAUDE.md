# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working Agreement (IMPORTANT)

This is a **learning project**: the user (Diyar) is porting his shipped iOS app to Flutter to learn Flutter/Dart and become an independent developer. Follow the mentorship contract in his user memory — **teach, hint, and review; the user writes the code himself.** Do not dump complete implementations unless he explicitly asks after attempting it. Explain the *why*, map concepts to SwiftUI (which he knows), and challenge his assumptions.

## Commands

```bash
flutter pub get          # install dependencies (after editing pubspec.yaml)
flutter run              # build + launch on the selected device/emulator
flutter emulators        # list Android emulators
flutter analyze          # lint (rules: flutter_lints via analysis_options.yaml)
flutter test             # run all tests
flutter test test/widget_test.dart   # run a single test file
```

Hot reload: save in IDE or press `r` in the `flutter run` terminal (`R` = hot restart).

## What this project is

Cross-platform (Android-first) port of the shipped iOS app **Boxing Interval Timer** (`/Users/diyar21/projects/Boxing timer/`, GitHub: mr-dzzs21/Box-Interval-Timer). The Flutter app must look **identical** to iOS v1.3.

**Design parity is driven by tokens, not by eye:** the iOS app's `Boxing timer/DesignSystem.swift` defines the canonical hex colors, type scale, spacing, radii, and component specs ("Bold/Athletic" forced-dark design). Port those values 1:1. Key rules: background color follows the timer **phase** (round = green `0xFF18A957`, rest = red `0xFFDC3B3B`, warmup/cooldown = gray, finished = blue), timer display stays large, accent is orange `0xFFFF7A1A`, no default Material blue/light chrome.

The iOS timer core is `TimerSessionEngine.swift` — a pure value type computing phase/remaining time from wall-clock time (drift-free, survives backgrounding), with unit tests in `Boxing timerTests/`. Port this engine (and its tests) rather than re-inventing tick-based timers.

## Current state

- `lib/main.dart` is still the counter template — no app code yet.
- `pubspec.yaml` already lists the full dependency set (added ahead of need by an agent); each maps to an iOS framework: sqflite→Core Data, shared_preferences→UserDefaults, audioplayers→AVAudioPlayer, flutter_tts→AVSpeechSynthesizer, wakelock_plus→isIdleTimerDisabled, in_app_purchase→StoreKit, flutter_local_notifications→UserNotifications, google_fonts→SF Rounded substitute, provider→state management.
- `assets/sounds/` contains `boxClock.mp3` and `warning10sec.mp3` copied from the iOS app (registered in pubspec).
- The iOS app supports 7 languages (de, en, ar incl. RTL, es, fr, ru, pt) via a custom `LanguageManager` — the port will need the same strings.

## Before any Play Store release

`applicationId`/`namespace` in `android/app/build.gradle.kts` is still `com.example.boxing_timer_flutter` — must be changed to a real ID before publishing (com.example is rejected by Play).
