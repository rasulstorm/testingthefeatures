import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/providers/family_group_providers.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'group_manage_screen.dart';
import 'group_create_screen.dart';

class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(familyGroupsProvider);
    final activeId = ref.watch(activeFamilyGroupIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Семейный доступ'),
        actions: [
          TextButton(
            onPressed: () {
              // Выход из family-режима
              ref.read(activeFamilyGroupIdProvider.notifier).state = null;
              Navigator.pop(context);
            },
            child: const Text('Личный', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupCreateScreen()),
            ),
        label: const Text('Создать группу'),
        icon: const Icon(Icons.group_add),
      ),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Групп пока нет'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final g = list[i];
              final bool isActive = g.id == activeId;
              return ListTile(
                title: Text(g.name, style: AppStyles.bodyText1(ctx)),
                subtitle: Text(
                  '${g.members.length} участников',
                  style: AppStyles.bodyText2(ctx),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.visibility,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.manage_accounts),
                      tooltip: 'Управление',
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => GroupManageScreen(
                                    groupId: g.id,
                                    name: g.name,
                                  ),
                            ),
                          ),
                    ),
                  ],
                ),
                onTap: () {
                  // Включаем family-режим и возвращаемся на HomeScreen
                  ref.read(activeFamilyGroupIdProvider.notifier).state = g.id;
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
