import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../constants/app_strings.dart';
import '../logging/app_logger.dart';

class VoiceListenResult {
  final bool started;
  final String? message;

  const VoiceListenResult({required this.started, this.message});
}

class VoiceSpeakResult {
  final bool success;
  final String? message;

  const VoiceSpeakResult({required this.success, this.message});
}

class VoiceService {
  final SpeechToText _stt;
  final FlutterTts _tts;

  bool _initialized = false;
  bool _listening = false;
  String? _lastErrorMessage;

  void Function(String text)? _sessionResultHandler;
  void Function()? _sessionStopHandler;
  String _latestRecognizedText = '';
  bool _sessionResultDelivered = false;

  VoiceService({SpeechToText? stt, FlutterTts? tts})
    : _stt = stt ?? SpeechToText(),
      _tts = tts ?? FlutterTts();

  Future<bool> init() async {
    return _ensureInitialized();
  }

  bool get isListening => _listening;

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;

    try {
      final available = await _stt.initialize(
        onError: _handleRecognitionError,
        onStatus: _handleRecognitionStatus,
      );
      _initialized = available;
      if (!available) {
        _lastErrorMessage = AppStrings.voicePermissionUnavailable;
      }
      return available;
    } catch (e, stackTrace) {
      _initialized = false;
      _lastErrorMessage = AppStrings.voiceInitUnavailable;
      AppLogger.warning('Voice init failed.', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  void _handleRecognitionError(SpeechRecognitionError error) {
    _lastErrorMessage = error.errorMsg;
    AppLogger.warning('Voice recognition error: ${error.errorMsg}');
    _emitPartialResultIfAny();
    _finishListeningSession();
  }

  void _handleRecognitionStatus(String status) {
    if (status == SpeechToText.notListeningStatus ||
        status == SpeechToText.doneStatus) {
      _emitPartialResultIfAny();
      _finishListeningSession();
    }
  }

  void _emitPartialResultIfAny() {
    final fallbackText = _latestRecognizedText.trim();
    if (fallbackText.isEmpty || _sessionResultDelivered) return;

    _sessionResultDelivered = true;
    _sessionResultHandler?.call(fallbackText.toLowerCase());
  }

  void _finishListeningSession() {
    final stopHandler = _sessionStopHandler;

    _sessionResultHandler = null;
    _sessionStopHandler = null;
    _latestRecognizedText = '';
    _sessionResultDelivered = false;
    _listening = false;

    stopHandler?.call();
  }

  Future<VoiceListenResult> listen({
    required void Function(String text) onResult,
    void Function()? onListeningStart,
    void Function()? onListeningStop,
  }) async {
    if (_listening) {
      return const VoiceListenResult(
        started: false,
        message: AppStrings.voiceAlreadyRunning,
      );
    }

    final available = await init();
    if (!available) {
      return VoiceListenResult(
        started: false,
        message: _lastErrorMessage ?? AppStrings.voiceRecognitionUnavailable,
      );
    }

    _lastErrorMessage = null;
    _latestRecognizedText = '';
    _sessionResultDelivered = false;
    _sessionResultHandler = onResult;
    _sessionStopHandler = onListeningStop;
    _listening = true;
    onListeningStart?.call();

    try {
      await _stt.listen(
        localeId: 'en_IN',
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;

          _latestRecognizedText = words;
          if (result.finalResult && !_sessionResultDelivered) {
            _sessionResultDelivered = true;
            _sessionResultHandler?.call(words.toLowerCase());
          }

          if (result.finalResult) {
            _finishListeningSession();
          }
        },
      );
      return const VoiceListenResult(started: true);
    } catch (e, stackTrace) {
      _lastErrorMessage = AppStrings.voiceCaptureFailed;
      AppLogger.warning(
        'Voice listen failed.',
        error: e,
        stackTrace: stackTrace,
      );
      _emitPartialResultIfAny();
      _finishListeningSession();
      return const VoiceListenResult(
        started: false,
        message: AppStrings.voiceCaptureFailedFallback,
      );
    }
  }

  Future<void> stop() async {
    try {
      await _stt.stop();
    } catch (_) {}
    _finishListeningSession();
  }

  Future<VoiceSpeakResult> speak(String text) async {
    if (text.trim().isEmpty) {
      return const VoiceSpeakResult(
        success: false,
        message: AppStrings.voiceSpeakEmpty,
      );
    }

    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.speak(text);
      return const VoiceSpeakResult(success: true);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Voice playback failed.',
        error: e,
        stackTrace: stackTrace,
      );
      return const VoiceSpeakResult(
        success: false,
        message: AppStrings.voiceSpeakFailed,
      );
    }
  }

  Future<void> dispose() async {
    await stop();
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
