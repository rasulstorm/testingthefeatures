import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'chat_stt_service.dart';

class ChatSttState {
  final bool listening;
  final bool available;
  final String partial;
  final String lastTranscript;
  final String lastMessage; // для SnackBar
  final String currentLocaleId; // активный язык
  final List<String> supportedLocales;

  const ChatSttState({
    this.listening = false,
    this.available = false,
    this.partial = '',
    this.lastTranscript = '',
    this.lastMessage = '',
    this.currentLocaleId = 'ru_RU',
    this.supportedLocales = const [],
  });

  ChatSttState copyWith({
    bool? listening,
    bool? available,
    String? partial,
    String? lastTranscript,
    String? lastMessage,
    String? currentLocaleId,
    List<String>? supportedLocales,
  }) {
    return ChatSttState(
      listening: listening ?? this.listening,
      available: available ?? this.available,
      partial: partial ?? this.partial,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastMessage: lastMessage ?? this.lastMessage,
      currentLocaleId: currentLocaleId ?? this.currentLocaleId,
      supportedLocales: supportedLocales ?? this.supportedLocales,
    );
  }
}

/// Контроллер STT только для AI-чата
final chatSttControllerProvider =
    StateNotifierProvider<ChatSttController, ChatSttState>((ref) {
      final svc = ref.read(chatSttServiceProvider);
      return ChatSttController(svc);
    });

class ChatSttController extends StateNotifier<ChatSttState> {
  ChatSttController(this._svc) : super(const ChatSttState());
  final ChatSttService _svc;

  Future<void> _ensureInit() async {
    if (state.available) return;

    final ok = await _svc.initialize(
      onStatus: (s) {
        final l = s.toLowerCase();
        if (l.contains('notlistening') || l.contains('done')) {
          state = state.copyWith(listening: false);
        }
      },
      onError: (_) {
        state = state.copyWith(listening: false);
      },
    );

    List<stt.LocaleName> locales = [];
    try {
      locales = await _svc.locales();
    } catch (_) {}

    final ids = locales.map((e) => e.localeId).toList();

    String pickLocale(List<String> ids) {
      String? pick = ids.firstWhere(
        (l) => l.toLowerCase().startsWith('ru'),
        orElse: () => '',
      );
      if (pick.isEmpty) {
        pick = ids.firstWhere(
          (l) => l.toLowerCase().startsWith('kk'),
          orElse: () => '',
        );
      }
      if (pick.isEmpty) {
        pick = ids.firstWhere(
          (l) => l.toLowerCase().startsWith('en'),
          orElse: () => ids.isNotEmpty ? ids.first : '',
        );
      }
      return pick;
    }

    final desired =
        ids.contains(state.currentLocaleId)
            ? state.currentLocaleId
            : pickLocale(ids);

    state = state.copyWith(
      available: ok,
      supportedLocales: ids,
      currentLocaleId: desired.isEmpty ? state.currentLocaleId : desired,
    );
  }

  Future<bool> start() async {
    await _ensureInit();
    if (!state.available) {
      state = state.copyWith(lastMessage: 'Распознавание речи недоступно');
      return false;
    }
    final loc = state.currentLocaleId;
    state = state.copyWith(
      listening: true,
      partial: '',
      lastMessage: 'Слушаю…',
    );

    final ok = await _svc.listen(
      localeId: loc,
      // onText приходит из ChatSttService: (String text, bool isFinal)
      onText: (text, isFinal) {
        if (isFinal) {
          state = state.copyWith(
            listening: false,
            lastTranscript: text,
            partial: '',
          );
        } else {
          state = state.copyWith(partial: text);
        }
      },
      partialResults: true,
    );

    if (!ok) {
      state = state.copyWith(
        listening: false,
        lastMessage: 'Не удалось начать прослушивание',
      );
    }
    return ok;
  }

  Future<void> stopAndCommit() async {
    await _svc.stop();
    final text =
        state.partial.isNotEmpty ? state.partial : state.lastTranscript;
    state = state.copyWith(
      listening: false,
      lastTranscript: text,
      partial: '',
      lastMessage: 'Остановлено',
    );
  }

  /// Отмена без фиксации — и чистим всё, чтобы поле не заполнялось снова.
  Future<void> cancel() async {
    await _svc.cancel();
    state = state.copyWith(
      listening: false,
      partial: '',
      lastTranscript: '', // <— важно, чтоб не вернулось в поле
      lastMessage: 'Отменено',
    );
  }

  void cycleLocale() {
    final ids = state.supportedLocales;
    if (ids.isEmpty) return;
    final idx = ids.indexOf(state.currentLocaleId);
    final next = ids[(idx + 1) % ids.length];
    state = state.copyWith(currentLocaleId: next, lastMessage: 'Язык: $next');
  }

  void setLocale(String id) {
    state = state.copyWith(currentLocaleId: id);
  }
}
