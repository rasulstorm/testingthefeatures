import 'package:flutter/material.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/appColor.dart';

class ObjectScreen extends StatelessWidget {
  final HubObject object;

  const ObjectScreen({Key? key, required this.object}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(object.facilityName),
        backgroundColor: AppColors.secodnBg,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация по хабу
            Text('Адрес:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Text(object.address, style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Text('ID Хаба:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Text(object.hubNumber, style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            Text('Статус:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            Text(
              object.statusNameRus,
              style: TextStyle(
                color: object.connected ? AppColors.iconGreen : AppColors.iconRed,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            const Text('Датчики:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),

            // Если датчиков нет, показываем сообщение
            if (object.devices.isEmpty)
              const Text('Датчики отсутствуют', style: TextStyle(color: Colors.white54, fontSize: 16))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: object.devices.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                  itemBuilder: (context, index) {
                    final device = object.devices[index];
                    final bool isActive = (device.parameters['active'] as bool?) ?? false;
                    final Color statusColor = isActive ? AppColors.iconGreen : AppColors.iconRed;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(device.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Последнее обновление: ${device.lastUpdate.toLocal()}',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      trailing: Icon(
                        isActive ? Icons.check_circle : Icons.error,
                        color: statusColor,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
