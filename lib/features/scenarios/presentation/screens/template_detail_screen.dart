// lib/features/scenarios/presentation/screens/template_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../../ widgets/device_picker_tile.dart';

class TemplateDetailScreen extends ConsumerWidget {
  final String templateKey;
  const TemplateDetailScreen({super.key, required this.templateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tpl = ref.watch(templateByKeyProvider(templateKey));
    final ctrl = ref.watch(createFromTemplateControllerProvider(templateKey));
    final ctrlNotifier = ref.read(
      createFromTemplateControllerProvider(templateKey).notifier,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Шаблон: $templateKey')),
      body: tpl.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          final msg = (e is Exception) ? e.toString() : '$e';
          return Center(child: Text('Не удалось открыть шаблон: $msg'));
        },
        data: (t) {
          final triggers = ref.watch(
            devicesByTemplateTypeProvider(t.triggerDeviceType),
          );
          final actions = ref.watch(
            devicesByTemplateTypeProvider(t.actionDeviceType),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(t.name, style: Theme.of(context).textTheme.titleLarge),
              if (t.description != null && t.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(t.description!),
                ),
              const SizedBox(height: 16),

              // -------- ТРИГГЕРЫ --------
              Text(
                'Триггеры (${t.triggerDeviceType})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              triggers.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(),
                    ),
                error:
                    (e, _) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Ошибка загрузки триггер-девайсов: $e'),
                    ),
                data:
                    (list) => Column(
                      children:
                          list
                              .map(
                                (d) => DevicePickerTile(
                                  d: d,
                                  // ВАЖНО: сравниваем по d.name, а не по d.id
                                  selected: ctrl.triggerDeviceIds.contains(
                                    d.name,
                                  ),
                                  onTap:
                                      () => ctrlNotifier.toggleTrigger(d.name),
                                ),
                              )
                              .toList(),
                    ),
              ),
              const SizedBox(height: 16),

              // -------- ДЕЙСТВИЯ --------
              Text(
                'Действия (${t.actionDeviceType})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              actions.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(),
                    ),
                error:
                    (e, _) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Ошибка загрузки девайсов действий: $e'),
                    ),
                data:
                    (list) => Column(
                      children:
                          list
                              .map(
                                (d) => DevicePickerTile(
                                  d: d,
                                  // Тоже по d.name
                                  selected: ctrl.actionDeviceIds.contains(
                                    d.name,
                                  ),
                                  onTap:
                                      () => ctrlNotifier.toggleAction(d.name),
                                ),
                              )
                              .toList(),
                    ),
              ),

              const SizedBox(height: 24),

              // -------- SUBMIT --------
              ctrl.status.when(
                data:
                    (_) => FilledButton.icon(
                      onPressed:
                          (ctrl.triggerDeviceIds.isEmpty ||
                                  ctrl.actionDeviceIds.isEmpty)
                              ? null
                              : () async {
                                try {
                                  await ctrlNotifier.submit();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Сценарий создан из шаблона',
                                        ),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ошибка: $e')),
                                    );
                                  }
                                }
                              },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Создать сценарий'),
                    ),
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                error:
                    (e, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ошибка: $e',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => ctrlNotifier.submit(),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
