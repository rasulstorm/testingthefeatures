// lib/features/family_access/family_group_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/features/family_access/family_group_service.dart';
import 'package:ISS/l10n/app_localizations.dart';

final groupDetailsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, groupId) async {
      final response = await dio.get('/family-group/$groupId');
      final data = response.data['data'];
      if (data is List && data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw Exception('Group not found or invalid response format');
    });

class FamilyGroupDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> group;
  const FamilyGroupDetailsScreen({super.key, required this.group});

  void _showAddMemberDialog(
    BuildContext context,
    WidgetRef ref,
    String groupId,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    String selectedRole = 'USER';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.getCardBackgroundColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.borderRadiusAll(16),
              ),
              title: Text(
                localizations.addMemberTitle,
                style: AppStyles.headline4(context),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: AppStyles.bodyText1(context),
                    decoration: InputDecoration(labelText: localizations.email),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    style: AppStyles.bodyText1(context),
                    dropdownColor: AppColors.getCardBackgroundColor(context),
                    decoration: InputDecoration(labelText: localizations.role),
                    items: [
                      DropdownMenuItem(
                        value: 'USER',
                        child: Text(localizations.userRole),
                      ),
                      DropdownMenuItem(
                        value: 'ADMIN',
                        child: Text(localizations.adminRole),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => selectedRole = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    localizations.cancel,
                    style: TextStyle(
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  style: AppStyles.primaryButtonStyle,
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            if (emailController.text.trim().isEmpty) return;
                            setState(() => isLoading = true);
                            try {
                              final service = ref.read(
                                familyGroupServiceProvider,
                              );
                              await service.addMemberToGroup(
                                groupId: groupId,
                                email: emailController.text.trim(),
                                role: selectedRole,
                              );
                              Navigator.pop(dialogContext);
                              ref.invalidate(groupDetailsProvider(groupId));
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              if (Navigator.of(dialogContext).canPop()) {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(
                            localizations.addMemberButton,
                            style: TextStyle(color: AppColors.textColorDark),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ИСПРАВЛЕННЫЙ МЕТОД: ДОБАВЛЕНА ЛОГИКА ЗАГРУЗКИ И ОБРАБОТКИ ОШИБОК ---
  void _showChangeRoleDialog(
    BuildContext context,
    WidgetRef ref,
    String memberId,
    String currentRoleFromServer,
  ) {
    final localizations = AppLocalizations.of(context)!;

    // --- ГЛАВНОЕ ИСПРАВЛЕНИЕ: ПРИВОДИМ 'MEMBER' К 'USER' ---
    String selectedRole =
        (currentRoleFromServer == 'MEMBER') ? 'USER' : currentRoleFromServer;

    bool isLoading = false;
    final groupId = group['id'] as String;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.getCardBackgroundColor(context),
              title: Text(
                localizations.changeRole,
                style: AppStyles.headline4(context),
              ),
              content: DropdownButtonFormField<String>(
                value: selectedRole,
                style: AppStyles.bodyText1(context),
                dropdownColor: AppColors.getCardBackgroundColor(context),
                items: [
                  DropdownMenuItem(
                    value: 'USER',
                    child: Text(localizations.userRole),
                  ),
                  DropdownMenuItem(
                    value: 'ADMIN',
                    child: Text(localizations.adminRole),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => selectedRole = value);
                },
              ),
              actions: [
                TextButton(
                  child: Text(localizations.cancel),
                  onPressed:
                      isLoading ? null : () => Navigator.pop(dialogContext),
                ),
                ElevatedButton(
                  child:
                      isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(localizations.save),
                  style: AppStyles.primaryButtonStyle,
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            setState(() => isLoading = true);
                            try {
                              final service = ref.read(
                                familyGroupServiceProvider,
                              );
                              await service.updateMemberRole(
                                memberId: memberId,
                                role: selectedRole,
                              );
                              Navigator.pop(dialogContext);
                              ref.invalidate(groupDetailsProvider(groupId));
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              if (dialogContext.mounted) {
                                setState(() => isLoading = false);
                              }
                            }
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ИСПРАВЛЕННЫЙ МЕТОД: ДОБАВЛЕНА ЛОГИКА ЗАГРУЗКИ И ОБРАБОТКИ ОШИБОК ---
  void _confirmDeleteMember(
    BuildContext context,
    WidgetRef ref,
    String memberId,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final groupId = group['id'] as String;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(context),
          title: Text(
            localizations.deleteMember,
            style: AppStyles.headline4(context),
          ),
          content: Text(
            localizations.confirmDeleteMember,
            style: AppStyles.bodyText1(context),
          ),
          actions: [
            TextButton(
              child: Text(localizations.cancel),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: Text(
                localizations.delete,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder:
                      (_) => const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                try {
                  final service = ref.read(familyGroupServiceProvider);
                  await service.deleteMember(memberId: memberId);

                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.pop(dialogContext);
                  ref.invalidate(groupDetailsProvider(groupId));
                } catch (e) {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = group['id'] as String;
    final groupDetailsAsync = ref.watch(groupDetailsProvider(groupId));
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(group['name']),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(groupDetailsProvider(groupId).future),
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.getCardBackgroundColor(context),
        child: groupDetailsAsync.when(
          data: (details) {
            final members = List<Map<String, dynamic>>.from(
              details['members'] ?? [],
            );
            if (members.isEmpty) {
              return Stack(
                children: [
                  ListView(),
                  Center(
                    child: Text(
                      localizations.noMembersInGroup,
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText2(context),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final memberId = member['id'] as String;
                final memberName = member['name'] as String? ?? 'No Name';
                final memberRole = member['role'] as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: AppStyles.cardDecoration(context),
                  child: ListTile(
                    tileColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.person_outline,
                      color: AppColors.primaryAccent,
                    ),
                    title: Text(
                      memberName,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      memberRole,
                      style: AppStyles.bodyText2(context).copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      color: AppColors.getCardBackgroundColor(context),
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'change_role',
                              child: Text(
                                localizations.changeRole,
                                style: AppStyles.bodyText1(context),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                localizations.deleteMember,
                                style: AppStyles.bodyText1(
                                  context,
                                ).copyWith(color: AppColors.error),
                              ),
                            ),
                          ],
                      onSelected: (value) {
                        if (value == 'change_role') {
                          _showChangeRoleDialog(
                            context,
                            ref,
                            memberId,
                            memberRole,
                          );
                        } else if (value == 'delete') {
                          _confirmDeleteMember(context, ref, memberId);
                        }
                      },
                    ),
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
        onPressed: () => _showAddMemberDialog(context, ref, groupId),
        label: Text(localizations.addMemberButton),
        icon: const Icon(Icons.person_add_alt_1),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: AppColors.textColorDark,
      ),
    );
  }
}
