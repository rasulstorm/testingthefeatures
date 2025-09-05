// lib/features/ai_chat/widgets/chat_stt_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import '../stt/chat_stt_controller.dart';

class ChatSttButton extends ConsumerWidget {
  const ChatSttButton({super.key, required this.textController});

  final TextEditingController textController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(chatSttControllerProvider);
    final ctrl = ref.read(chatSttControllerProvider.notifier);
    final isOn = st.listening;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isOn ? 52 : 0,
              height: isOn ? 52 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withOpacity(0.20),
              ),
            ),
            IconButton.filledTonal(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  isOn
                      ? AppColors.primaryAccent
                      : AppColors.getCardBackgroundColor(context),
                ),
                foregroundColor: const WidgetStatePropertyAll(
                  AppColors.textColorDark,
                ),
              ),
              icon: Icon(isOn ? Icons.mic : Icons.mic_none),
              tooltip: isOn ? 'Остановить и очистить' : 'Начать диктовку',
              onPressed: () async {
                if (!isOn) {
                  // старт с “чистого листа”
                  textController.clear();
                  final ok = await ctrl.start();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Речь недоступна или нет разрешений'),
                      ),
                    );
                  }
                } else {
                  // второе нажатие: отмена и очистка
                  await ctrl
                      .cancel(); // <- см. п.3 ниже (чистит lastTranscript)
                  textController.clear(); // <- чистим поле
                }
              },
              onLongPress: () {
                // Быстрая смена языка по удержанию
                ctrl.cycleLocale();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Язык: ${st.currentLocaleId}')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isOn
              ? 'Слушаю…'
              : (st.lastTranscript.isEmpty
                  ? st.currentLocaleId
                  : st.lastTranscript),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
