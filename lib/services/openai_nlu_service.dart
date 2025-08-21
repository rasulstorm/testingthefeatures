import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Простая обёртка вокруг OpenAI Chat Completions для извлечения интента в JSON.
/// Ответ всегда приводим к унифицированной схеме.
class OpenAiNluService {
  final Dio _dio;
  final String _model;

  OpenAiNluService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl:
                  dotenv.env['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1',
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
                'Content-Type': 'application/json',
              },
            ),
          ),
      _model = dotenv.env['OPENAI_MODEL'] ?? 'gpt-4o-mini';

  /// Возвращает JSON-карту:
  /// {
  ///   "intent": "change_language" | "toggle_light" | "unknown",
  ///   "language": "ru|en|kk",                 // если change_language
  ///   "device_name": "string", "state": "on|off" // если toggle_light
  /// }
  Future<Map<String, dynamic>> extractIntent(
    String text, {
    String? locale,
  }) async {
    // Фьюшот-промпт: жёстко просим JSON, без других слов
    final system = '''
Ты NLU-парсер для умного дома. Верни ЧИСТЫЙ JSON без комментариев и текста вокруг.
Поддерживаемые интенты:
- change_language: сменить язык приложения. Ключ "language" одно из: "ru", "en", "kk".
- toggle_light: включить/выключить свет/лампу/освещение. Ключи: "device_name" (строка, как сказал пользователь), "state": "on"|"off".
Если намерение непонятно — intent = "unknown".
Примеры ответов:
{"intent":"change_language","language":"ru"}
{"intent":"toggle_light","device_name":"кухня лампа","state":"on"}
{"intent":"unknown"}
''';

    final user =
        'Пользователь сказал: "$text". Текущий язык: ${locale ?? 'ru'}. Верни ТОЛЬКО JSON.';

    final payload = {
      "model": _model,
      "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user},
      ],
      "temperature": 0.1,
    };

    final resp = await _dio.post('/chat/completions', data: payload);
    final content =
        (resp.data['choices'] as List).first['message']['content'] as String;
    // На всякий случай вырезаем код-блоки, если модель вдруг добавит ```json
    final cleaned =
        content.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      final map = json.decode(cleaned) as Map<String, dynamic>;
      return map;
    } catch (_) {
      return {"intent": "unknown"};
    }
  }
}
