// lib/features/home/sheets/hub_selection_sheet.dart
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/features/home/sheets/glass_sheet_container.dart';

Future<HubObject?> showHubSelectionSheet({
  required BuildContext context,
  required List<HubObject> hubs,
  required String? selectedHubId,
}) {
  final loc = AppLocalizations.of(context);
  return showModalBottomSheet<HubObject>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder:
        (_) => glassSheetContainer(
          context: context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sheetHeader(context, loc.selectHub),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: ListView.builder(
                  itemCount: hubs.length,
                  itemBuilder: (_, i) {
                    final hub = hubs[i];
                    final isSelected = hub.commandHubId == selectedHubId;
                    return ListTile(
                      title: Text(
                        hub.facilityName,
                        style: AppStyles.bodyText1(context).copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected
                                  ? AppColors.primaryAccent
                                  : AppColors.getTextColor(context),
                        ),
                      ),
                      subtitle: Text(
                        hub.commandHubId,
                        style: AppStyles.caption(context),
                      ),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryAccent,
                              )
                              : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppStyles.borderRadiusAll(12),
                      ),
                      onTap: () => Navigator.pop(context, hub),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
  );
}
