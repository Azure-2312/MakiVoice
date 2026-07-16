import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> _initTts() async {
    if (_isInitialized) return;
    await _tts.setLanguage("es-ES");   // Español de España/Latinoamérica
    await _tts.setSpeechRate(0.65);     // Velocidad de lectura más rápida para deletreo
    await _tts.setVolume(1.0);         // Volumen completo
    await _tts.setPitch(1.0);          // Tono de voz normal
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    await _initTts();
    if (text.trim().isNotEmpty) {
      await _tts.stop(); // Detener cualquier reproducción en curso
      await _tts.speak(text);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setPitch(double pitch) async {
    await _initTts();
    await _tts.setPitch(pitch);
  }

  Future<void> setSpeechRate(double rate) async {
    await _initTts();
    await _tts.setSpeechRate(rate);
  }
}
