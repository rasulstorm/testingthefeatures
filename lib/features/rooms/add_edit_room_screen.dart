// lib/features/rooms/add_edit_room_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/rooms/rooms_service.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/space_model.dart';
import 'package:ISS/providers/hubs_provider.dart';

class AddEditRoomScreen extends ConsumerStatefulWidget {
  final Space space;
  final Room? room;

  const AddEditRoomScreen({super.key, required this.space, this.room});

  @override
  ConsumerState<AddEditRoomScreen> createState() => _AddEditRoomScreenState();
}

class _AddEditRoomScreenState extends ConsumerState<AddEditRoomScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nameController.text = widget.room!.name;
    }
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final service = ref.read(roomsServiceProvider);
    final isEditing = widget.room != null;

    try {
      if (isEditing) {
        await service.updateRoomName(
          widget.space.id,
          widget.room!.id,
          _nameController.text.trim(),
        );
      } else {
        await service.createRoom(widget.space.id, _nameController.text.trim());
      }

      // Обновляем getObjects, чтобы комнаты перезалились
      await ref.refresh(hubsProvider.future);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRoom() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            title: Text(localizations.deleteRoomTitle),
            content: Text(
              localizations.deleteRoomConfirmation(widget.room!.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  localizations.delete,
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(roomsServiceProvider)
            .deleteRoom(widget.space.id, widget.room!.id);
        await ref.refresh(hubsProvider.future);
        context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isEditing = widget.room != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? localizations.editRoom : localizations.addRoom),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                localizations.name,
                TextFormField(
                  controller: _nameController,
                  style: AppStyles.bodyText1(context),
                  decoration: InputDecoration.collapsed(
                    hintText: localizations.roomName,
                  ).copyWith(
                    hintStyle: AppStyles.bodyText1(
                      context,
                    ).copyWith(color: AppColors.getSecondaryTextColor(context)),
                  ),
                  validator:
                      (value) =>
                          (value == null || value.trim().isEmpty)
                              ? localizations.fieldCannotBeEmpty
                              : null,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveRoom,
                style: AppStyles.primaryButtonStyle,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(localizations.save),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isLoading ? null : _deleteRoom,
                  child: Text(
                    localizations.delete,
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.bodyText2(context)),
          const SizedBox(height: 4),
          content,
        ],
      ),
    );
  }
}
