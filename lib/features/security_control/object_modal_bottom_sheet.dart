// lib/features/security/object_modal_bottom_sheet.dart

import 'package:ISS/features/security_control/security_provider.dart'; // Ensure this path is correct
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/models/hub_models.dart'; // Import your new models

class ObjectModalBottomSheet extends ConsumerStatefulWidget {
  final HubObject object; // Changed type to HubObject
  final BuildContext rootContext;

  const ObjectModalBottomSheet({
    super.key,
    required this.object,
    required this.rootContext,
  });

  @override
  ConsumerState<ObjectModalBottomSheet> createState() =>
      _ObjectModalBottomSheetState();
}

class _ObjectModalBottomSheetState
    extends ConsumerState<ObjectModalBottomSheet> {
  bool _alarmCooldown = false;
  bool _isProcessingCommand = false;

  @override
  Widget build(BuildContext context) {
    final hubObject = widget.object; // Use hubObject for clarity
    final hubId = hubObject.id; // Access id from HubObject
    final statusName = hubObject.statusName; // Access statusName from HubObject
    final isActive = statusName == 'SECURITY_ACTIVE';
    final isSleep = statusName == 'SECURITY_SLEEP';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secodnBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            hubObject.facilityName, // Access facilityName from HubObject
            style: const TextStyle(
                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Адрес: ${hubObject.address}", // Access address from HubObject
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            "Статус: ${hubObject.statusNameRus}", // Access statusNameRus from HubObject
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          // Command buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSleep || _isProcessingCommand
                      ? null
                      : () async {
                          setState(() => _isProcessingCommand = true);
                          try {
                            final command = isActive ? 'disarm' : 'arm';
                            final response = await ref
                                .read(securityCommandProvider)
                                .sendCommand(hubId, command);

                            final data = response.data;
                            final msg = data['message'] ?? 'Нет сообщения';
                            final code = data['code'] ?? 1;

                            if (mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) {
                                ScaffoldMessenger.of(
                                  widget.rootContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(msg),
                                    backgroundColor:
                                        code == 0 ? null : Colors.red,
                                  ),
                                );
                              });

                              Navigator.pop(context);
                              ref.invalidate(objectsProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          } finally {
                            setState(() => _isProcessingCommand = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.primary : AppColors.iconGreen, // Dynamic color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isProcessingCommand && !isSleep
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isActive
                              ? 'Снять с охраны'
                              : 'Поставить на охрану',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _alarmCooldown || _isProcessingCommand
                      ? null
                      : () async {
                          setState(() {
                            _alarmCooldown = true;
                            _isProcessingCommand = true;
                          });

                          try {
                            final response = await ref
                                .read(securityCommandProvider)
                                .triggerAlarm(hubId);
                            final data = response.data;
                            final msg = data['message'] ?? 'Нет сообщения';
                            final code = data['code'] ?? 1;

                            if (mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) {
                                ScaffoldMessenger.of(
                                  widget.rootContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(msg),
                                    backgroundColor:
                                        code == 0 ? null : Colors.red,
                                  ),
                                );
                              });

                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                widget.rootContext,
                              ).showSnackBar(
                                SnackBar(content: Text('Ошибка: $e')),
                              );
                            }
                          } finally {
                            Future.delayed(const Duration(minutes: 1), () {
                              if (mounted) {
                                setState(() => _alarmCooldown = false);
                              }
                            });
                            if (mounted) {
                              setState(() => _isProcessingCommand = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isProcessingCommand && _alarmCooldown
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Тревога", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Devices Section
          Text(
            'Устройства на хабе (${hubObject.devices.length}):',
            style: TextStyle(
              color: AppColors.heading,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (hubObject.devices.isEmpty)
            const Text(
              'Устройств на этом хабе не найдено.',
              style: TextStyle(color: Colors.white70),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hubObject.devices.length,
              itemBuilder: (context, index) {
                final device = hubObject.devices[index];
                return Card(
                  color: AppColors.background, // Use background for device cards
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Последнее обновление: ${_formatDateTime(device.lastUpdate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (device.room != null)
                          Text(
                            'Комната: ${device.room!.name}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        if (device.group != null)
                          Text(
                            'Группа: ${device.group!.name}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        // Add more device parameters here if needed
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text('Закрыть'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}