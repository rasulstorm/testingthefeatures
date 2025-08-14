// lib/features/family_access/family_groups_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/providers/hubs_provider.dart';

// Провайдер для получения списка семейных групп
final familyGroupsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final response = await dio.get('/family-group');
  return response.data['data'] ?? [];
});

class FamilyGroupsScreen extends ConsumerWidget {
  const FamilyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(familyGroupsProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.familyAccess,
          style: AppStyles.headline3(context),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(familyGroupsProvider.future),
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.getCardBackgroundColor(context),
        child: groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    localizations.noFamilyGroups,
                    style: AppStyles.bodyText1(context),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final membersList = group['members'] as List?;
                final memberCount = membersList?.length ?? 0;

                // Используем Container с вашим AppStyles.cardDecoration, это надежнее чем Card
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: AppStyles.cardDecoration(context),
                  child: ListTile(
                    // У ListTile tileColor должен быть прозрачным, чтобы видеть фон контейнера
                    tileColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      group['name'],
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      '${localizations.members}: $memberCount',
                      style: AppStyles.bodyText2(context),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    onTap: () {
                      context.push('/family-group-details', extra: group);
                    },
                    onLongPress: () {
                      final groupId = group['id'] as String;
                      ref.read(activeFamilyGroupIdProvider.notifier).state =
                          groupId;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${localizations.familyAccess} "${group['name']}"',
                          ),
                        ),
                      );
                      context.go('/main');
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: AppStyles.borderRadiusAll(12),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-family-group'),
        icon: const Icon(Icons.add),
        label: Text(localizations.createGroup),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.textColorDark,
      ),
    );
  }
}
