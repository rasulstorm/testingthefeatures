import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart'; // ваш Singleton Dio
import 'models/ai_chat_models.dart';

final aiChatServiceProvider = Provider<AiChatService>((ref) {
  return AiChatService(dio);
});

class AiChatService {
  AiChatService(this._dio);
  final Dio _dio;

  static const _prefix = '/open-ai'; // baseUrl уже содержит /api/v1

  Future<List<AiChatItem>> getChatsByUser() async {
    final res = await _dio.get('$_prefix/chat/by-user');
    final data = res.data?['data'];
    if (data is! List) return const <AiChatItem>[];
    final list =
        data
            .map((e) => AiChatItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort(AiChatItem.compareAsc); // старые сверху
    return list;
  }

  Future<AiChatItem> createDialog({
    required String hubId,
    required String text,
  }) async {
    final res = await _dio.post(
      '$_prefix/chat-dialog',
      data: {'hubId': hubId, 'text': text},
    );
    final data = res.data?['data'];
    if (data is Map) {
      return AiChatItem.fromJson(Map<String, dynamic>.from(data));
    }
    // fallback: подтянем последнюю запись
    final list = await getChatsByUser();
    return list.isNotEmpty
        ? list.last
        : AiChatItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          request: text,
          response: '',
          createdAt: DateTime.now(),
        );
  }

  Future<AiChatItem> getById(String id) async {
    final res = await _dio.get('$_prefix/chat/$id');
    final data = Map<String, dynamic>.from(res.data?['data'] ?? {});
    return AiChatItem.fromJson(data);
  }
}
