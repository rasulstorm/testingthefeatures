// lib/features/home/sheets/image_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/home/sheets/glass_sheet_container.dart';

Future<ImageSource?> showImagePickerSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (_) => glassSheetContainer(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.getSecondaryTextColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Камера'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Галерея'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
  );
}
