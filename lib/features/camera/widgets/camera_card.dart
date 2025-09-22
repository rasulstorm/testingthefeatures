import 'package:flutter/material.dart';
import '../domain/camera_models.dart';

class CameraCard extends StatelessWidget {
  final Camera cam;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CameraCard({
    super.key,
    required this.cam,
    required this.onTap,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  bool get _enabled => cam.status == CameraStatus.ENABLED;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surface;
    final fg = theme.colorScheme.onSurface;
    final badgeColor = _enabled ? Colors.green : theme.colorScheme.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(.06),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(.4),
          ),
        ),
        child: Column(
          children: [
            // Header/preview placeholder
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // заглушка вместо превью
                    Container(color: Colors.black),
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        _enabled ? Icons.videocam : Icons.videocam_off,
                        color: Colors.white30,
                        size: 40,
                      ),
                    ),
                    // статус-точка
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.45),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _enabled ? 'ONLINE' : 'OFFLINE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                letterSpacing: .3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Meta + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cam.cameraModel ?? 'Камера',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _enabled ? 'Отключить' : 'Включить',
                    onPressed: onToggle,
                    icon: Icon(
                      _enabled ? Icons.power_settings_new : Icons.power,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder:
                        (ctx) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Редактировать'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Удалить'),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
