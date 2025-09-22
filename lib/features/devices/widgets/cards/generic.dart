import 'package:flutter/material.dart';
import '../device_card_base.dart';

class GenericCard extends StatelessWidget {
  final String deviceId;
  final String title;
  final String room;
  final String asset;
  const GenericCard({
    super.key,
    required this.deviceId,
    required this.title,
    required this.room,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return DeviceCardBase(
      deviceId: deviceId,
      title: title,
      subtitle: room,
      asset: asset,
      gradient: const LinearGradient(
        colors: [Color(0xFF5E6472), Color(0xFF2C2F36)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
