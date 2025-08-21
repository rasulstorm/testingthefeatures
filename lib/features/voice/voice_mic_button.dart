import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/features/voice/voice_controller.dart';
import 'package:ISS/appColor.dart';

class VoiceMicButton extends ConsumerWidget {
  const VoiceMicButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(voiceControllerProvider);
    final ctrl = ref.read(voiceControllerProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(
              st.listening
                  ? AppColors.primaryAccent
                  : AppColors.getCardBackgroundColor(context),
            ),
            foregroundColor: const WidgetStatePropertyAll(
              AppColors.textColorDark,
            ),
          ),
          onPressed: () async {
            if (!st.listening) {
              await ctrl.startListening();
            } else {
              await ctrl.stopAndProcess();
              if (context.mounted && st.lastActionMessage.isNotEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(st.lastActionMessage)));
              }
            }
          },
          icon: Icon(st.listening ? Icons.mic : Icons.mic_none),
        ),
        const SizedBox(height: 6),
        Text(
          st.listening
              ? 'Говорите...'
              : (st.lastTranscript.isEmpty
                  ? 'Нажми и скажи'
                  : st.lastTranscript),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
