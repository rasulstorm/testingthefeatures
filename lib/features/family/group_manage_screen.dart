import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/providers/family_group_providers.dart';

class GroupManageScreen extends ConsumerWidget {
  final String groupId;
  final String name;
  const GroupManageScreen({
    super.key,
    required this.groupId,
    required this.name,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(familyGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Группа: $name')),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (list) {
          final g = list.firstWhere(
            (x) => x.id == groupId,
            orElse: () => list.first,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Участники', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...g.members.map(
                (m) => ListTile(
                  title: Text(m.name),
                  subtitle: Text('Роль: ${m.role}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (role) async {
                      await dio.put(
                        '/family-group/${m.id}/update-member-role',
                        queryParameters: {'role': role},
                      );
                      ref.invalidate(familyGroupsProvider);
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(value: 'OWNER', child: Text('OWNER')),
                          PopupMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                          PopupMenuItem(value: 'USER', child: Text('USER')),
                          PopupMenuItem(value: 'GUEST', child: Text('GUEST')),
                        ],
                  ),
                  onLongPress: () async {
                    await dio.delete('/family-group/${m.id}/delete-member');
                    ref.invalidate(familyGroupsProvider);
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final newName = await _ask(
                    context,
                    'Новое имя группы',
                    g.name,
                  );
                  if (newName == null || newName.trim().isEmpty) return;
                  await dio.put(
                    '/family-group/$groupId/update-group-name',
                    queryParameters: {'name': newName.trim()},
                  );
                  ref.invalidate(familyGroupsProvider);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Переименовать группу'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _ask(BuildContext ctx, String title, String initial) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: ctx,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: TextField(controller: c, autofocus: true),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, c.text),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
