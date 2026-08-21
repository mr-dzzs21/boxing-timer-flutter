import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Mirrors the iOS `SoundManager.SoundType` enum (ModelsAndStubs.swift).
enum SoundType {
  roundStart,
  roundEnd,
  workoutEnd,

  /// 10 seconds before the end of a round.
  roundWarning,
}

/// Port of the iOS `SoundManager` singleton (ModelsAndStubs.swift).
///
/// - Bell sounds (`roundStart`, `roundEnd`, `workoutEnd`) play boxClock.mp3 on
///   the main player; `roundWarning` plays warning10sec.mp3 on a dedicated
///   second player so it never cuts off the bell (and vice versa).
/// - Audio ducks other sources (music) instead of stopping them, matching the
///   iOS `.mixWithOthers` + `.duckOthers` session options.
/// - `speakRound` announces the round number via TTS, cancelling any speech
///   that is still in progress.
class SoundManager {
  SoundManager._();

  static final SoundManager instance = SoundManager._();

  static const String _bellAsset = 'sounds/boxClock.mp3';
  static const String _warningAsset = 'sounds/warning10sec.mp3';

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _audioContextConfigured = false;

  Future<void> _configureAudioContext() async {
    if (_audioContextConfigured) return;
    _audioContextConfigured = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('SoundManager: could not configure audio context: $e');
    }
  }

  /// Plays the sound for [t]. No-op when [soundEnabled] is false.
  Future<void> play(SoundType t, {required bool soundEnabled}) async {
    if (!soundEnabled) return;
    await _configureAudioContext();

    try {
      if (t == SoundType.roundWarning) {
        // Warning runs on its own player, independent of the bell.
        await _warningPlayer.stop();
        await _warningPlayer.play(AssetSource(_warningAsset), volume: 1.0);
        return;
      }

      // iOS volumes: roundStart 1.0, roundEnd 0.8, workoutEnd 1.0.
      final double volume = t == SoundType.roundEnd ? 0.8 : 1.0;
      await _player.stop();
      await _player.play(AssetSource(_bellAsset), volume: volume);
    } catch (e) {
      debugPrint('SoundManager: could not play sound: $e');
    }
  }

  /// Haptic feedback matching the iOS generators:
  /// roundStart = heavy impact, roundEnd/workoutEnd = notification-style
  /// (medium impact on Flutter), roundWarning = light tap.
  void haptic(SoundType t, {required bool vibrationEnabled}) {
    if (!vibrationEnabled) return;

    switch (t) {
      case SoundType.roundStart:
        HapticFeedback.heavyImpact();
        break;
      case SoundType.roundEnd:
        HapticFeedback.mediumImpact();
        break;
      case SoundType.workoutEnd:
        HapticFeedback.mediumImpact();
        break;
      case SoundType.roundWarning:
        HapticFeedback.lightImpact();
        break;
    }
  }

  /// Announces "Round [round]" via TTS — always in English, matching the iOS
  /// app (which speaks English regardless of the selected UI language).
  /// Cancels any speech still in progress.
  Future<void> speakRound(int round, {required bool soundEnabled}) async {
    if (!soundEnabled) return;

    try {
      await _tts.stop();
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.speak('Round $round');
    } catch (e) {
      debugPrint('SoundManager: could not speak round: $e');
    }
  }

  /// Speaks a Combo Trainer phrase (e.g. "1 2 3" or "Jab, Cross, Lead Hook")
  /// via TTS — always English, slightly faster than round announcements to
  /// match the pace combos are called at. Cancels any speech in progress.
  Future<void> speakCombo(String phrase, {required bool soundEnabled}) async {
    if (!soundEnabled) return;

    try {
      await _tts.stop();
      await _tts.setLanguage('en-US');
      // A touch slower + neutral pitch reads the punch names more clearly.
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.speak(phrase);
    } catch (e) {
      debugPrint('SoundManager: could not speak combo: $e');
    }
  }
}
