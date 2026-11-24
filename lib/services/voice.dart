import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Speech-to-text for asking, text-to-speech for reading answers aloud.
class Voice {
  Voice._();
  static final Voice instance = Voice._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;
  bool get isListening => _stt.isListening;

  Future<bool> _initStt() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize();
    } catch (_) {
      _sttReady = false;
    }
    return _sttReady;
  }

  /// Starts listening. [onText] gets the words so far; [isFinal] is true at the end.
  /// Returns false if the microphone or speech service is not available.
  Future<bool> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onText,
  }) async {
    if (!await _initStt()) return false;
    await _stt.listen(
      localeId: localeId,
      onResult: (r) => onText(r.recognizedWords, r.finalResult),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
    return true;
  }

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> speak(String text, String ttsLocale, {void Function()? onDone}) async {
    await _tts.stop();
    await _tts.setLanguage(ttsLocale);
    await _tts.setSpeechRate(0.45);
    _tts.setCompletionHandler(() => onDone?.call());
    _tts.setCancelHandler(() => onDone?.call());
    await _tts.speak(_plain(text));
  }

  Future<void> stopSpeaking() => _tts.stop();

  // Remove markdown symbols so they are not read out.
  static String _plain(String s) => s
      .replaceAllMapped(RegExp(r'\[(.*?)\]\((.*?)\)'), (m) => m.group(1) ?? '')
      .replaceAll(RegExp(r'https?://\S+'), '')
      .replaceAll(RegExp(r'[*_#`>]'), '');
}
