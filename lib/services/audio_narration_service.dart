import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum NarrationVoiceState {
  stopped,
  playing,
  paused,
}

/// Unified, crash-proof Audio Narration & Text-to-Speech (TTS) Service.
///
/// Powers both:
/// 1. Real-time AR Pedestrian Navigation (turn maneuvers, door detection, obstacle warnings).
/// 2. Immersive Cultural Attraction Storytelling & Audio Guides (historical scripts).
class AudioNarrationService {
  static final AudioNarrationService _instance = AudioNarrationService._internal();
  factory AudioNarrationService() => _instance;
  AudioNarrationService._internal() {
    _initTts();
  }

  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isMuted = false;
  NarrationVoiceState _state = NarrationVoiceState.stopped;

  String _lastSpokenPrompt = '';
  DateTime? _lastSpokenTime;

  // Streams for UI synchronization
  final StreamController<NarrationVoiceState> _stateController =
      StreamController<NarrationVoiceState>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Stream<NarrationVoiceState> get stateStream => _stateController.stream;
  Stream<double> get progressStream => _progressController.stream;

  bool get isSpeaking => _state == NarrationVoiceState.playing;
  bool get isMuted => _isMuted;
  NarrationVoiceState get state => _state;

  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48); // Natural, clear walking pace
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _state = NarrationVoiceState.playing;
        if (!_stateController.isClosed) _stateController.add(_state);
      });

      _tts.setCompletionHandler(() {
        _state = NarrationVoiceState.stopped;
        if (!_stateController.isClosed) _stateController.add(_state);
        if (!_progressController.isClosed) _progressController.add(1.0);
      });

      _tts.setCancelHandler(() {
        _state = NarrationVoiceState.stopped;
        if (!_stateController.isClosed) _stateController.add(_state);
      });

      _tts.setErrorHandler((msg) {
        _state = NarrationVoiceState.stopped;
        if (!_stateController.isClosed) _stateController.add(_state);
      });

      _tts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
        if (text.isNotEmpty) {
          final progress = (endOffset / text.length).clamp(0.0, 1.0);
          if (!_progressController.isClosed) _progressController.add(progress);
        }
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[AudioNarrationService] TTS init notice: $e');
    }
  }

  /// Sets voice language (e.g. 'en-US' or 'am-ET' for Amharic if supported)
  Future<void> setLanguage(String langCode) async {
    try {
      await _tts.setLanguage(langCode);
    } catch (_) {}
  }

  /// Toggles voice navigation mute
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted && isSpeaking) {
      stop();
    }
  }

  void setMuted(bool mute) {
    _isMuted = mute;
    if (_isMuted && isSpeaking) {
      stop();
    }
  }

  /// Speaks a real-time turn-by-turn navigation or door detection prompt.
  /// Includes smart de-duplication to avoid annoying tourists by repeating the same
  /// prompt every few seconds.
  Future<void> speakNavigationPrompt(String rawPrompt, {bool force = false}) async {
    if (_isMuted) return;

    final prompt = _cleanPromptForSpeech(rawPrompt);
    if (prompt.isEmpty) return;

    final now = DateTime.now();
    if (!force &&
        _lastSpokenPrompt == prompt &&
        _lastSpokenTime != null &&
        now.difference(_lastSpokenTime!).inSeconds < 9) {
      return; // Skip duplicate prompt within 9 seconds
    }

    _lastSpokenPrompt = prompt;
    _lastSpokenTime = now;

    try {
      await _tts.stop();
      await _tts.speak(prompt);
    } catch (e) {
      debugPrint('[AudioNarrationService] Navigation prompt error: $e');
    }
  }

  /// Speaks a full historical storytelling narration script (Audio Guide mode)
  Future<void> speakStory(String storyText) async {
    final text = storyText.trim();
    if (text.isEmpty) return;

    try {
      await _tts.stop();
      if (!_progressController.isClosed) _progressController.add(0.0);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[AudioNarrationService] Story speech error: $e');
    }
  }

  /// Pauses active narration
  Future<void> pause() async {
    try {
      await _tts.pause();
      _state = NarrationVoiceState.paused;
      if (!_stateController.isClosed) _stateController.add(_state);
    } catch (_) {
      await stop();
    }
  }

  /// Stops active narration
  Future<void> stop() async {
    try {
      await _tts.stop();
      _state = NarrationVoiceState.stopped;
      if (!_stateController.isClosed) _stateController.add(_state);
    } catch (_) {}
  }

  /// Cleans instructions of raw arrows, distance abbreviations, and emoji symbols
  /// for natural pronunciation.
  String _cleanPromptForSpeech(String input) {
    var s = input
        .replaceAll(RegExp(r'[➜⬅↑↷⚠️⇈📍🚪🪜🚶]'), '')
        .replaceAll('NOW:', 'Now,')
        .replaceAll(RegExp(r'\b(\d+)\s*m\b'), r'$1 meters')
        .replaceAll(RegExp(r'\b(\d+(\.\d+)?)\s*km\b'), r'$1 kilometers')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s;
  }

  void dispose() {
    _stateController.close();
    _progressController.close();
    _tts.stop();
  }
}

