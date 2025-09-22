// lib/features/devices/screens/unknown_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/devices/device_catalog.dart';

class UnknownDetailScreen extends StatelessWidget {
  const UnknownDetailScreen({super.key, required this.vm});
  final DeviceCardVm vm;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.getPrimaryTextColor(context);
    final sub = AppColors.getSecondaryTextColor(context);
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(vm.title, style: TextStyle(color: text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppColors.glassGradient(context),
              border: Border.all(color: AppColors.getGlassBorderColor(context)),
            ),
            child: Center(child: Image.asset(vm.asset, height: 110)),
          ),
          const SizedBox(height: 16),
          Text(
            'Пока нет специализированной детали для этого устройства.',
            style: TextStyle(color: sub),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${vm.deviceId}',
            style: TextStyle(color: text, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
