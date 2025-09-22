// lib/features/scenarios/presentation/screens/scenarios_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scenario_models.dart';
import '../../data/scenarios_repository.dart';
import '../providers.dart';

import '../../ widgets/scenario_card.dart';
import '../../ widgets/template_card_pro.dart';

import 'template_detail_screen.dart';
import 'scenario_editor_screen.dart';

class ScenariosScreen extends ConsumerWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Сценарии'),
          bottom: const TabBar(tabs: [Tab(text: 'Мои'), Tab(text: 'Шаблоны')]),
          actions: [
            IconButton(
              tooltip: 'Создать сценарий',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ScenarioEditorScreen(),
                  ),
                );
                if (ok == true) {
                  ref.invalidate(scenariosByHubProvider);
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ======== Мои сценарии ========
            RefreshIndicator(
              onRefresh: () => ref.refresh(scenariosByHubProvider.future),
              child: Consumer(
                builder: (_, r, __) {
                  final st = r.watch(scenariosByHubProvider);
                  return st.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (e, _) => ListView(
                          children: [ListTile(title: Text('Ошибка: $e'))],
                        ),
                    data:
                        (list) =>
                            list.isEmpty
                                ? ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: const [
                                    ListTile(title: Text('Сценариев пока нет')),
                                  ],
                                )
                                : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: list.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (_, i) {
                                    final s = list[i];
                                    return ScenarioCard(
                                      s: s,
                                      onEdit: () async {
                                        final ok = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ScenarioEditorScreen(
                                                  scenario: s,
                                                ),
                                          ),
                                        );
                                        if (ok == true) {
                                          r.invalidate(scenariosByHubProvider);
                                        }
                                      },
                                      onDelete: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (_) => AlertDialog(
                                                title: const Text(
                                                  'Удалить сценарий?',
                                                ),
                                                content: Text(s.json.name),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text('Отмена'),
                                                  ),
                                                  FilledButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      'Удалить',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );
                                        if (ok == true) {
                                          await r
                                              .read(scenariosRepositoryProvider)
                                              .delete(s.id);
                                          r.invalidate(scenariosByHubProvider);
                                        }
                                      },
                                      onToggleEnabled: (val) async {
                                        // быстрый тоггл включения с PUT
                                        final json = s.json;
                                        final updated = ScenarioJson(
                                          name: json.name,
                                          hubId: json.hubId,
                                          enabled: val,
                                          triggers: json.triggers,
                                          conditions: json.conditions,
                                          actions: json.actions,
                                        );
                                        await r
                                            .read(scenariosRepositoryProvider)
                                            .update(s.id, updated);
                                        r.invalidate(scenariosByHubProvider);
                                      },
                                    );
                                  },
                                ),
                  );
                },
              ),
            ),

            // ======== Шаблоны ========
            Consumer(
              builder: (_, r, __) {
                final st = r.watch(scenarioTemplatesProvider);
                return st.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Ошибка: $e')),
                  data:
                      (list) => ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final t = list[i];
                          return TemplateCardPro(
                            t: t,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => TemplateDetailScreen(
                                          templateKey: t.key,
                                        ),
                                  ),
                                ),
                          );
                        },
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
