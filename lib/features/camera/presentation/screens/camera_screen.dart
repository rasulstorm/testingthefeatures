import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/camera_models.dart';
import '../../data/cameras_repository.dart';
import '../providers.dart';
import '../../widgets/camera_card.dart';
import '../../widgets/camera_form_sheet.dart';
import 'camera_detail_screen.dart';

class CamerasScreen extends ConsumerWidget {
  const CamerasScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final req = await showModalBottomSheet<CameraRequest>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => const CameraFormSheet(),
    );
    if (req == null) return;
    await ref.read(camerasRepositoryProvider).create(req);
    ref.invalidate(camerasProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Камера создана')));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Camera cam) async {
    final req = await showModalBottomSheet<CameraRequest>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => CameraFormSheet(initial: cam),
    );
    if (req == null) return;
    await ref.read(camerasRepositoryProvider).update(cam.id, req);
    ref.invalidate(camerasProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(camerasProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
      body: SafeArea(
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (list) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(camerasProvider.future),
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    title: const Text('Камеры'),
                    centerTitle: false,
                    floating: true,
                  ),
                  if (list.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Пока нет ни одной камеры'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: .86,
                            ),
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final c = list[i];
                          return CameraCard(
                            cam: c,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CameraDetailScreen(id: c.id),
                                ),
                              );
                            },
                            onToggle: () async {
                              final repo = ref.read(camerasRepositoryProvider);
                              if (c.status == CameraStatus.ENABLED) {
                                await repo.deactivate(c.id);
                              } else {
                                await repo.activate(c.id);
                              }
                              ref.invalidate(camerasProvider);
                            },
                            onEdit: () => _edit(context, ref, c),
                            onDelete: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Удалить камеру?'),
                                      content: Text(c.cameraModel ?? c.id),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Отмена'),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Удалить'),
                                        ),
                                      ],
                                    ),
                              );
                              if (ok == true) {
                                await ref
                                    .read(camerasRepositoryProvider)
                                    .delete(c.id);
                                ref.invalidate(camerasProvider);
                              }
                            },
                          );
                        }, childCount: list.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
