// lib/widgets/control_device_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/utils/device_parser.dart'; // <-- Важный импорт

class ControlDeviceCard extends ConsumerWidget {
  final BaseDevice device;
  final String commandHubId;

  const ControlDeviceCard({
    Key? key,
    required this.device,
    required this.commandHubId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    // --- ИСПРАВЛЕНИЕ: Теперь мы берем "живые" данные из провайдера ---
    final liveData =
        ref.watch(webSocketNotifierProvider).deviceData[device.friendlyName];
    // Сливаем исходные данные с "живыми" и пере-парсим, чтобы получить самый актуальный объект
    final currentDevice =
        liveData != null
            ? DeviceParser.parse({...device.rawData, ...liveData})
            : device;

    final bool isOn =
        (currentDevice is ControllableDevice)
            ? (currentDevice as ControllableDevice).isOn
            : false;

    final cardColor =
        isOn
            ? AppColors.primaryAccent
            : AppColors.getCardBackgroundColor(context);
    final textColor =
        isOn ? AppColors.textColorDark : AppColors.getTextColor(context);
    final iconColor = isOn ? AppColors.textColorDark : AppColors.primaryAccent;

    final mainLabelText = DeviceUtils.getLocalizedDeviceTypeName(
      currentDevice,
      localizations,
    );
    final mainIcon = DeviceUtils.getIconForDevice(currentDevice);
    String subStatusText = isOn ? localizations.on : localizations.off;

    if (currentDevice is DimmableLightDevice) {
      final brightnessPercent =
          ((currentDevice.brightness / 254) * 100).round();
      subStatusText =
          isOn
              ? '${localizations.on} • $brightnessPercent%'
              : localizations.off;
    }

    return Container(
      decoration: AppStyles.cardDecoration(context).copyWith(color: cardColor),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppStyles.borderRadiusAll(12),
          onLongPress:
              () => _showDeviceControlModal(
                context,
                currentDevice,
                commandHubId,
                localizations,
                ref,
              ),
          onTap: () {
            if (currentDevice is ControllableDevice) {
              final newState = !isOn;
              // --- ИСПРАВЛЕНИЕ: Используем friendlyName (Zigbee ID) ---
              ref
                  .read(webSocketNotifierProvider.notifier)
                  .updateDeviceLocalState(currentDevice.friendlyName, {
                    'state': newState ? 'ON' : 'OFF',
                  });
              ref.read(webSocketNotifierProvider.notifier).sendDeviceCommand(
                commandHubId,
                currentDevice.friendlyName,
                {"state": newState ? "ON" : "OFF"},
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(mainIcon, color: iconColor, size: 32),
                const Spacer(),
                Text(
                  mainLabelText,
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: textColor, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentDevice.friendlyName,
                  style: AppStyles.caption(
                    context,
                  ).copyWith(color: textColor.withOpacity(0.8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subStatusText,
                  style: AppStyles.bodyText2(
                    context,
                  ).copyWith(color: textColor.withOpacity(0.8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showDeviceControlModal(
  BuildContext context,
  BaseDevice device, // Принимаем начальное состояние устройства
  String commandHubId,
  AppLocalizations localizations,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.getBackgroundColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext bc) {
      return Consumer(
        // Используем Consumer, чтобы модальное окно обновлялось
        builder: (context, widgetRef, child) {
          // --- ИСПРАВЛЕНИЕ: Следим за "живыми" данными для этого устройства ---
          final liveData =
              widgetRef.watch(webSocketNotifierProvider).deviceData[device
                  .friendlyName];
          final currentDevice =
              liveData != null
                  ? DeviceParser.parse({...device.rawData, ...liveData})
                  : device;

          final bool isOn =
              (currentDevice is ControllableDevice)
                  ? (currentDevice as ControllableDevice).isOn
                  : false;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      currentDevice.friendlyName,
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: AppColors.getBorderGrayColor(context)),
                  const SizedBox(height: 10),

                  if (currentDevice is DimmableLightDevice) ...[
                    Builder(
                      builder: (context) {
                        final dimmableDevice =
                            currentDevice; // Тип уже правильный
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.brightness,
                              style: AppStyles.bodyText1(
                                context,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: dimmableDevice.brightness.toDouble(),
                                    min: 0,
                                    max: 254,
                                    divisions: 254,
                                    activeColor: AppColors.primaryAccent,
                                    onChanged:
                                        (value) => widgetRef
                                            .read(
                                              webSocketNotifierProvider
                                                  .notifier,
                                            )
                                            .updateDeviceLocalState(
                                              dimmableDevice.friendlyName,
                                              {'brightness': value.toInt()},
                                            ),
                                    // --- ИСПРАВЛЕНИЕ: Отправляем friendlyName ---
                                    onChangeEnd:
                                        (value) => widgetRef
                                            .read(
                                              webSocketNotifierProvider
                                                  .notifier,
                                            )
                                            .sendDeviceCommand(
                                              commandHubId,
                                              dimmableDevice.friendlyName,
                                              {"brightness": value.toInt()},
                                            ),
                                  ),
                                ),
                                Text(
                                  '${(dimmableDevice.brightness / 254 * 100).round()}%',
                                  style: AppStyles.bodyText1(
                                    context,
                                  ).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ],

                  if (currentDevice is ControllableDevice)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildOnOffButton(
                            context,
                            ref,
                            currentDevice,
                            commandHubId,
                            true,
                            isOn,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildOnOffButton(
                            context,
                            ref,
                            currentDevice,
                            commandHubId,
                            false,
                            isOn,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildOnOffButton(
  BuildContext context,
  WidgetRef ref,
  BaseDevice device,
  String commandHubId,
  bool targetStateIsOn,
  bool currentStateIsOn,
) {
  final localizations = AppLocalizations.of(context)!;
  final bool isActive = targetStateIsOn == currentStateIsOn;

  return ElevatedButton.icon(
    onPressed: () {
      // --- ИСПРАВЛЕНИЕ: Используем friendlyName ---
      ref.read(webSocketNotifierProvider.notifier).updateDeviceLocalState(
        device.friendlyName,
        {'state': targetStateIsOn ? 'ON' : 'OFF'},
      );
      ref.read(webSocketNotifierProvider.notifier).sendDeviceCommand(
        commandHubId,
        device.friendlyName,
        {"state": targetStateIsOn ? "ON" : "OFF"},
      );
    },
    icon: Icon(
      targetStateIsOn ? Icons.lightbulb_sharp : Icons.lightbulb_outline,
      color:
          isActive
              ? (targetStateIsOn ? AppColors.textColorDark : AppColors.error)
              : (targetStateIsOn
                  ? AppColors.primaryAccent
                  : AppColors.getTextColor(context)),
    ),
    label: Text(
      targetStateIsOn ? localizations.on : localizations.off,
      style: AppStyles.bodyText2(context).copyWith(
        color:
            isActive
                ? AppColors.textColorDark
                : AppColors.getTextColor(context),
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor:
          isActive
              ? AppColors.primaryAccent
              : AppColors.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
    ),
  );
}
