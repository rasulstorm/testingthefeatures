// lib/features/home/widgets/control_device_grid.dart
import 'package:flutter/material.dart';
import 'package:ISS/widgets/control_device_card.dart';
import 'package:ISS/models/device_models.dart';

class ControlDeviceGrid extends StatelessWidget {
  final List<BaseDevice> devices;
  final String commandHubId;

  const ControlDeviceGrid({
    super.key,
    required this.devices,
    required this.commandHubId,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: devices.length,
        itemBuilder:
            (_, i) => ControlDeviceCard(
              device: devices[i],
              commandHubId: commandHubId,
            ),
      ),
    );
  }
}
