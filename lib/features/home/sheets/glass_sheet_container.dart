// lib/features/home/sheets/glass_sheet_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ISS/appstyles.dart';

Widget glassSheetContainer({
  required BuildContext context,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (ctx, constraints) {
      final maxW = constraints.maxWidth;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Container(
              decoration: AppStyles.glassmorphicBoxDecoration(context).copyWith(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: MediaQuery.of(ctx)
                      .viewInsets
                      .add(const EdgeInsets.fromLTRB(20, 12, 20, 20)),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget sheetHeader(BuildContext context, String title) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      Text(title, style: AppStyles.headline3(context)),
      const SizedBox(height: 12),
    ],
  );
}
