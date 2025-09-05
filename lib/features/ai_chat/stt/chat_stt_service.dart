import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Provider сервиса STT только для AI-чата
final chatSttServiceProvider = Provider<ChatSttService>((ref) {
  return ChatSttService();
});

/// Обёртка над speech_to_text без жёстких ссылок на внутренние типы
class ChatSttService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Инициализация движка.
  /// onStatus: "listening" / "notListening" / др.
  /// onError: любой объект ошибки (dynamic), чтобы не тянуть типы из пакета.
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(dynamic error)? onError,
  }) async {
    return _speech.initialize(
      onStatus: onStatus,
      // Не указываем тип параметра, пусть выведется из сигнатуры пакета.
      onError: onError == null ? null : (e) => onError(e),
    );
  }

  Future<List<stt.LocaleName>> locales() => _speech.locales();

  bool get isAvailable => _speech.isAvailable;

  /// Старт запись/распознавание.
  /// onText: отдаём просто текст и флаг финальности.
  Future<bool> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onText,
    bool partialResults = true,
  }) async {
    final ok = await _speech.listen(
      localeId: localeId,
      partialResults: partialResults,
      listenMode: stt.ListenMode.dictation,
      // res имеет пакетный тип, но мы его не называем, просто читаем поля.
      onResult: (res) {
        final text = (res.recognizedWords ?? '').toString();
        final isFinal = (res.finalResult == true);
        onText(text, isFinal);
      },
    );
    return ok;
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();
}
