import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';

class DeviceDetailsModal extends StatelessWidget {
  final dynamic device;

  const DeviceDetailsModal({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secodnBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device['name'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _info('Тип', device['type']['description']),
          _info('Комната', device['room']?['name']),
          _info('Пространство', device['space']?['name']),
          _info('Webhook URL', device['hiteProWebhookURL']),
        ],
      ),
    );
  }

  Widget _info(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$title: ${value ?? '-'}",
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
