import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _listening = false;

  Future<bool> init() async {
    return await _stt.initialize();
  }

  bool get isListening => _listening;

  Future<void> listen({
    required void Function(String text) onResult,
    void Function()? onListeningStart,
    void Function()? onListeningStop,
  }) async {
    if (_listening) return;

    final available = await init();
    if (!available) return;

    _listening = true;
    onListeningStart?.call();

    await _stt.listen(
      localeId: 'en_IN',
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _listening = false;
          onListeningStop?.call();
          onResult(result.recognizedWords.toLowerCase());
        }
      },
    );
  }

  Future<void> stop() async {
    await _stt.stop();
    _listening = false;
  }

  Future<void> speak(String text) async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> dispose() async {
    await _stt.stop();
    await _tts.stop();
  }
}
