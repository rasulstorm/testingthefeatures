import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'avatar_controller.dart';
import 'package:ISS/appColor.dart';

class AvatarPickerTile extends ConsumerWidget {
  const AvatarPickerTile({super.key, this.title = 'Аватар'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(avatarControllerProvider);
    final ctrl = ref.read(avatarControllerProvider.notifier);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.getCardBackgroundColor(context),
            backgroundImage:
                (st.url != null && st.url!.isNotEmpty)
                    ? NetworkImage(st.url!)
                    : null,
            child:
                (st.url == null || st.url!.isEmpty)
                    ? const Icon(Icons.person, size: 28)
                    : null,
          ),
          if (st.loading)
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: st.progress > 0 && st.progress < 1 ? st.progress : null,
                strokeWidth: 3,
              ),
            ),
        ],
      ),
      title: Text(title),
      subtitle:
          st.error == null
              ? Text(
                st.loading
                    ? 'Загрузка… ${(st.progress * 100).toStringAsFixed(0)}%'
                    : (st.url == null ? 'Не задан' : 'Нажмите, чтобы изменить'),
                style: Theme.of(context).textTheme.bodySmall,
              )
              : Text(st.error!, style: TextStyle(color: AppColors.error)),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _showSourceSheet(context, ctrl),
        tooltip: 'Изменить',
      ),
      onTap: () => _showSourceSheet(context, ctrl),
    );
  }

  void _showSourceSheet(BuildContext context, AvatarController ctrl) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Сфотографировать'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ctrl.pickAndUpload(camera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Выбрать из галереи'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ctrl.pickAndUpload(camera: false);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
