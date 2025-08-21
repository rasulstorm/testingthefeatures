// lib/features/voice/voice_command_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCommandService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Начать слушать, распознать и отправить в OpenAI
  Future<String> listenAndProcess() async {
    // 1. Проверяем доступность
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (err) => print('Speech error: $err'),
    );

    if (!available) {
      return "Speech recognition not available";
    }

    // 2. Слушаем и ждем результат
    final completer = Completer<String>();
    _speech.listen(
      localeId: "ru-RU", // можно en-US
      onResult: (result) {
        if (result.finalResult) {
          _speech.stop();
          completer.complete(result.recognizedWords);
        }
      },
    );

    final spokenText = await completer.future;
    print("🎤 User said: $spokenText");

    // 3. Отправляем в OpenAI
    final aiResponse = await _askOpenAI(spokenText);

    return aiResponse;
  }

  Future<String> _askOpenAI(String userText) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    final baseUrl =
        dotenv.env['OPENAI_BASE_URL'] ?? "https://api.openai.com/v1";
    final model = dotenv.env['OPENAI_MODEL'] ?? "gpt-4o-mini";

    final url = Uri.parse("$baseUrl/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": model,
        "messages": [
          {
            "role": "system",
            "content":
                "Ты управляешь умным домом. Отвечай короткой командой: turnOnLight, turnOffLight, switchLanguageRu, switchLanguageEn и т.д.",
          },
          {"role": "user", "content": userText},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data["choices"][0]["message"]["content"];
      print("🤖 AI replied: $content");
      return content;
    } else {
      print("OpenAI error: ${response.body}");
      return "Error from AI";
    }
  }
}
