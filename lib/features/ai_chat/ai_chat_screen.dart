import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';

import 'ai_chat_providers.dart';
import 'package:ISS/features/ai_chat/models/ai_chat_models.dart' as chat;

import 'stt/chat_stt_controller.dart';
import 'widgets/chat_stt_button.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _scroll = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          Consumer(
            builder: (_, ref, __) {
              final auto = ref.watch(autoSpeakProvider);
              return IconButton(
                tooltip: auto ? 'Авто-озвучка: ВКЛ' : 'Авто-озвучка: ВЫКЛ',
                icon: Icon(auto ? Icons.volume_up : Icons.volume_off),
                onPressed:
                    () => ref.read(autoSpeakProvider.notifier).state = !auto,
              );
            },
          ),
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed:
                () => ref.read(chatControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: state.when(
                data: (messages) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Спросите меня о чём угодно.\nНапример: «Какая погода в Алмате?»',
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyText2(context),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => _MessageBubble(msg: messages[i]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Ошибка загрузки: $e',
                        style: AppStyles.bodyText1(
                          context,
                        ).copyWith(color: AppColors.error),
                      ),
                    ),
              ),
            ),
            const _ComposerBar(), // поле ввода + чатовая STT-кнопка
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final chat.UiMessage msg;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final bg =
        isUser
            ? AppColors.primaryAccent.withOpacity(0.18)
            : AppColors.getCardBackgroundColor(context);
    final fg = AppColors.getTextColor(context);
    final radius =
        isUser
            ? const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            );

    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child:
                  msg.pending == chat.PendingKind.sending
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _TypingDots(),
                          const SizedBox(width: 8),
                          Text('Думаю...', style: AppStyles.bodyText2(context)),
                        ],
                      )
                      : Text(
                        msg.text,
                        style: AppStyles.bodyText1(context).copyWith(color: fg),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = (_c.value * 3).floor() % 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final on = i <= v;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Opacity(
            opacity: on ? 1 : 0.25,
            child: const CircleAvatar(radius: 3),
          ),
        );
      }),
    );
  }
}

class _ComposerBar extends ConsumerStatefulWidget {
  const _ComposerBar();

  @override
  ConsumerState<_ComposerBar> createState() => _ComposerBarState();
}

class _ComposerBarState extends ConsumerState<_ComposerBar> {
  final _controller = TextEditingController();
  ProviderSubscription<ChatSttState>? _sub;
  String _lastApplied = '';

  @override
  void initState() {
    super.initState();
    // При диктовке: partial -> сразу в поле, финал -> закрепляем.
    _sub = ref.listenManual<ChatSttState>(chatSttControllerProvider, (
      prev,
      next,
    ) {
      if (next.listening) {
        final p = next.partial;
        if (p.isNotEmpty && p != _lastApplied) {
          _lastApplied = p;
          _controller.text = p;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      } else {
        final f = next.lastTranscript;
        if (f.isNotEmpty && f != _lastApplied) {
          _lastApplied = f;
          _controller.text = f;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.close();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _lastApplied = '';
    await ref.read(chatControllerProvider.notifier).send(text);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.getBackgroundColor(context),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.getBackgroundColor(context),
            border: Border(
              top: BorderSide(color: AppColors.getBorderGrayColor(context)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Скажите или введите сообщение…',
                    filled: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              // ВАЖНО: сюда передаём _controller (кнопка на второе нажатие чистит поле)
              ChatSttButton(textController: _controller),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _send,
                icon: const Icon(Icons.send),
                label: const Text('Отпр.'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textColorDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
