import 'package:ISS/features/security_control/security_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../appColor.dart';

class ObjectModalBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> object;
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
    final object = widget.object;
    final hubId = object['id'];
    final statusName = object['hubStatus']['name'];
    final isActive = statusName == 'SECURITY_ACTIVE';
    final isSleep = statusName == 'SECURITY_SLEEP';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.secodnBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            object['facilityName'],
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Адрес: ${object['address']}",
            style: const TextStyle(color: AppColors.text),
          ),
          Text(
            "Статус: ${object['hubStatus']['description']}",
            style: const TextStyle(color: AppColors.text),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      isSleep || _isProcessingCommand
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
                  child:
                      _isProcessingCommand
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            isActive ? 'Снять с охраны' : 'Поставить на охрану',
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _alarmCooldown || _isProcessingCommand
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
                                if (mounted)
                                  setState(() => _alarmCooldown = false);
                              });
                              if (mounted)
                                setState(() => _isProcessingCommand = false);
                            }
                          },

                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child:
                      _isProcessingCommand && _alarmCooldown
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text("Тревога"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
