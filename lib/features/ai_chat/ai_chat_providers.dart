import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:ISS/providers/selected_hub_provider.dart';
import 'package:ISS/features/ai_chat/models/ai_chat_models.dart' as chat;
import 'ai_chat_service.dart';

/// Озвучка ответов
final ttsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  tts.setLanguage('ru-RU');
  tts.setSpeechRate(0.45);
  tts.setVolume(1.0);
  tts.setPitch(1.0);
  return tts;
});

/// Тумблер «авто-озвучка ответов»
final autoSpeakProvider = StateProvider<bool>((_) => true);

/// HubId для чата (если нет — дефолт)
final hubIdForChatProvider = Provider<String>((ref) {
  final selected = ref.watch(selectedHubIdProvider);
  return (selected == null || selected.isEmpty) ? 'isshub_default' : selected;
});

/// История чатов пользователя
final chatHistoryProvider = FutureProvider<List<chat.AiChatItem>>((ref) async {
  final api = ref.read(aiChatServiceProvider);
  return api.getChatsByUser();
});

/// История -> лента UI (по порядку: запрос, потом ответ)
final chatUiMessagesProvider = FutureProvider<List<chat.UiMessage>>((
  ref,
) async {
  final history = await ref.watch(chatHistoryProvider.future);
  final list = <chat.UiMessage>[];
  for (final item in history) {
    list.add(
      chat.UiMessage(
        id: '${item.id}_req',
        text: item.request,
        isUser: true,
        createdAt: item.createdAt,
      ),
    );
    final resp = item.response.trim();
    if (resp.isNotEmpty) {
      list.add(
        chat.UiMessage(
          id: '${item.id}_res',
          text: resp,
          isUser: false,
          createdAt: item.createdAt.add(const Duration(milliseconds: 1)),
        ),
      );
    }
  }
  return list;
});

/// Контроллер ленты
class ChatController extends StateNotifier<AsyncValue<List<chat.UiMessage>>> {
  ChatController(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }
  final Ref ref;

  Future<void> _init() async {
    try {
      final msgs = await ref.read(chatUiMessagesProvider.future);
      state = AsyncValue.data(msgs);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _init();
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final hubId = ref.read(hubIdForChatProvider);

    final now = DateTime.now();
    final tempUser = chat.UiMessage(
      id: 'local_${now.microsecondsSinceEpoch}_req',
      text: trimmed,
      isUser: true,
      createdAt: now,
      pending: chat.PendingKind.none,
    );
    final tempAssistant = chat.UiMessage(
      id: 'local_${now.microsecondsSinceEpoch}_res',
      text: '…',
      isUser: false,
      createdAt: now.add(const Duration(milliseconds: 1)),
      pending: chat.PendingKind.sending,
    );

    final current = state.value ?? const <chat.UiMessage>[];
    state = AsyncValue.data([...current, tempUser, tempAssistant]);

    try {
      final api = ref.read(aiChatServiceProvider);
      final item = await api.createDialog(hubId: hubId, text: trimmed);

      final updated =
          List<chat.UiMessage>.from(current)
            ..add(tempUser)
            ..add(
              chat.UiMessage(
                id: '${item.id}_res',
                text:
                    item.response.trim().isEmpty
                        ? 'Готово.'
                        : item.response.trim(),
                isUser: false,
                createdAt: item.createdAt.add(const Duration(milliseconds: 1)),
                pending: chat.PendingKind.none,
              ),
            );

      state = AsyncValue.data(updated);

      // Авто-озвучка
      if (ref.read(autoSpeakProvider)) {
        final tts = ref.read(ttsProvider);
        await tts.stop();
        await tts.speak(
          item.response.trim().isEmpty ? 'Готово.' : item.response.trim(),
        );
      }
    } catch (e, s) {
      final fixed = List<chat.UiMessage>.from(state.value ?? const []);
      if (fixed.isNotEmpty) {
        final last = fixed.removeLast(); // tempAssistant
        if (!last.isUser) {
          fixed.add(
            last.copyWith(
              text: 'Не удалось получить ответ: $e',
              pending: chat.PendingKind.none,
            ),
          );
        } else {
          fixed.add(last);
        }
      }
      state = AsyncValue.data(fixed);
      // ignore: avoid_print
      print('Chat send error: $e\n$s');
    }
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, AsyncValue<List<chat.UiMessage>>>(
      (ref) => ChatController(ref),
    );
