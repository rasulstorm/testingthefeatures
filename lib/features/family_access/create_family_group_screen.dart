// lib/features/family_access/create_family_group_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/family_access/family_group_service.dart';
import 'package:ISS/features/family_access/family_groups_screen.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/providers/hubs_provider.dart';

class CreateFamilyGroupScreen extends ConsumerStatefulWidget {
  const CreateFamilyGroupScreen({super.key});

  @override
  ConsumerState<CreateFamilyGroupScreen> createState() =>
      _CreateFamilyGroupScreenState();
}

class _CreateFamilyGroupScreenState
    extends ConsumerState<CreateFamilyGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailsController = TextEditingController();
  HubObject? _selectedHub;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailsController.dispose();
    super.dispose();
  }

  // --- ИСПРАВЛЕННЫЙ МЕТОД: ИСПОЛЬЗУЕМ TRY-CATCH ---
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final localizations = AppLocalizations.of(context)!;
    final service = ref.read(familyGroupServiceProvider);
    final emails =
        _emailsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    try {
      // 1. Просто вызываем метод. Он либо выполнится, либо выбросит исключение.
      await service.createGroup(
        name: _nameController.text.trim(),
        emails: emails,
        hubId: _selectedHub!.commandHubId,
      );

      // 2. Если исключения не было, значит все прошло успешно.
      if (mounted) {
        ref.invalidate(familyGroupsProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.success), // TODO: Добавить локализацию
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // 3. Если было исключение, ловим его и показываем ошибку.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()), // Показываем текст ошибки из сервиса
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // 4. В любом случае выключаем индикатор загрузки.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(
    BuildContext context,
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppStyles.bodyText1(
        context,
      ).copyWith(color: AppColors.getSecondaryTextColor(context)),
      hintStyle: AppStyles.bodyText2(
        context,
      ).copyWith(color: AppColors.getLightGreyColor(context)),
      filled: true,
      fillColor: AppColors.getCardBackgroundColor(context),
      border: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide(color: AppColors.getBorderGrayColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
        borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hubsAsync = ref.watch(hubsProvider);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.createNewGroup),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: hubsAsync.when(
        data: (hubs) {
          if (hubs.isEmpty) {
            return Center(child: Text(localizations.noHubsForSharing));
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nameController,
                  style: AppStyles.bodyText1(context),
                  decoration: _buildInputDecoration(
                    context,
                    localizations.groupName,
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? localizations.fieldCannotBeEmpty
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailsController,
                  style: AppStyles.bodyText1(context),
                  decoration: _buildInputDecoration(
                    context,
                    localizations.memberEmails,
                    hint: localizations.emailsHint,
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? localizations.fieldCannotBeEmpty
                              : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<HubObject>(
                  value: _selectedHub,
                  hint: Text(
                    localizations.selectHub,
                    style: AppStyles.bodyText2(
                      context,
                    ).copyWith(color: AppColors.getSecondaryTextColor(context)),
                  ),
                  style: AppStyles.bodyText1(context),
                  decoration: _buildInputDecoration(
                    context,
                    localizations.selectHubLabel,
                  ),
                  dropdownColor: AppColors.getCardBackgroundColor(context),
                  iconEnabledColor: AppColors.getTextColor(context),
                  items:
                      hubs
                          .map(
                            (hub) => DropdownMenuItem(
                              value: hub,
                              child: Text(hub.facilityName),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _selectedHub = value),
                  validator:
                      (value) =>
                          value == null ? localizations.pleaseSelectHub : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createGroup,
                  style: AppStyles.primaryButtonStyle,
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            localizations.create,
                            style: TextStyle(color: AppColors.textColorDark),
                          ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
