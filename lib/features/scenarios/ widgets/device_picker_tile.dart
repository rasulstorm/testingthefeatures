// lib/features/scenarios/widgets/device_picker_tile.dart
import 'package:flutter/material.dart';
import '../../scenarios/domain/scenario_models.dart';

class DevicePickerTile extends StatelessWidget {
  final DeviceSummary d;
  final bool selected;
  final VoidCallback onTap;
  const DevicePickerTile({
    super.key,
    required this.d,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Безопасно работаем с nullable title:
    final title =
        (d.title != null && d.title!.trim().isNotEmpty)
            ? d.title!.trim()
            : d.name;

    final room = (d.roomName ?? '').trim();
    final parts = <String>[
      if (room.isNotEmpty) room,
      d.deviceCategory,
      if (d.lastUpdate != null) 'обновл: ${d.lastUpdate!.toLocal()}',
    ];
    final subtitle = parts.join(' • ');

    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onTap(),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
    );
  }
}
