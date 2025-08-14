// lib/utils/device_utils.dart

import 'package:flutter/material.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/widgets/status_indicator_card.dart';
import 'package:ISS/appColor.dart';

class IndicatorValue {
  final String label;
  final String value;
  IndicatorValue(this.label, this.value);
}

class GroupedStatusIndicator {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool hasAlert;
  final List<IndicatorValue> values;

  GroupedStatusIndicator({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.hasAlert = false,
    required this.values,
  });
}

class DeviceUtils {
  // --- ИСПРАВЛЕННЫЙ МЕТОД ---
  static List<BaseDevice> getControllableDevices(List<BaseDevice> allDevices) {
    // Фильтруем список, оставляя только те элементы, которые "подмешали" в себя ControllableDevice
    return allDevices.where((device) => device is ControllableDevice).toList();
  }

  static List<StatusIndicator> createStatusIndicators(
    List<BaseDevice> allDevices,
    AppLocalizations localizations,
    BuildContext context,
  ) {
    final List<StatusIndicator> indicators = [];

    for (final device in allDevices) {
      if (device is TempHumiditySensorDevice) {
        indicators.add(
          StatusIndicator(
            label: localizations.tempShort,
            value: "${device.temperature.toStringAsFixed(1)}°",
            subLabel: device.friendlyName,
            icon: Icons.thermostat,
            hasAlert: device.temperature > 30 || device.temperature < 5,
          ),
        );
        indicators.add(
          StatusIndicator(
            label: localizations.humidityShort,
            value: "${device.humidity.toStringAsFixed(0)}%",
            subLabel: device.friendlyName,
            icon: Icons.water_drop_outlined,
            hasAlert: device.humidity > 70 || device.humidity < 20,
          ),
        );
      } else if (device is ContactSensorDevice) {
        indicators.add(
          StatusIndicator(
            label: localizations.doorNoun,
            value:
                device.isClosed
                    ? localizations.doorClosedShort
                    : localizations.open,
            subLabel: device.friendlyName,
            icon:
                device.isClosed
                    ? Icons.sensor_door
                    : Icons.sensor_door_outlined,
            hasAlert: !device.isClosed,
          ),
        );
      } else if (device is MotionSensorDevice) {
        indicators.add(
          StatusIndicator(
            label: localizations.occupancy,
            value:
                device.hasMotion ? localizations.detected : localizations.clear,
            subLabel: device.friendlyName,
            icon: device.hasMotion ? Icons.directions_run : Icons.person_off,
            hasAlert: device.hasMotion,
          ),
        );
        if (device.illuminance != null) {
          indicators.add(
            StatusIndicator(
              label: localizations.lightLevel,
              value: "${device.illuminance} Lux",
              subLabel: device.friendlyName,
              icon: Icons.light_mode_outlined,
            ),
          );
        }
      } else if (device is PresenceSensorDevice) {
        indicators.add(
          StatusIndicator(
            label: localizations.presence,
            value:
                device.isPresent ? localizations.detected : localizations.clear,
            subLabel: device.friendlyName,
            icon: device.isPresent ? Icons.person : Icons.person_off,
            hasAlert: device.isPresent,
          ),
        );
      } else if (device is LeakSensorDevice) {
        indicators.add(
          StatusIndicator(
            label: localizations.waterLeak,
            value:
                device.hasLeak ? localizations.detected : localizations.clear,
            subLabel: device.friendlyName,
            icon: Icons.water_drop,
            hasAlert: device.hasLeak,
          ),
        );
      }
    }
    return indicators;
  }

  static IconData getIconForDevice(BaseDevice device) {
    if (device is DimmableLightDevice) return Icons.lightbulb_outline;
    if (device is OnOffSwitchDevice) return Icons.power_settings_new;
    if (device is ContactSensorDevice) return Icons.sensor_door_outlined;
    if (device is MotionSensorDevice) return Icons.directions_run;
    if (device is PresenceSensorDevice) return Icons.person_search;
    if (device is TempHumiditySensorDevice) return Icons.thermostat_outlined;
    if (device is LeakSensorDevice) return Icons.water_drop;

    return Icons.device_hub_outlined;
  }

  static String getLocalizedDeviceTypeName(
    BaseDevice device,
    AppLocalizations localizations,
  ) {
    if (device is DimmableLightDevice) return localizations.dimmer;
    if (device is OnOffSwitchDevice) return localizations.switchDevice;
    if (device is ContactSensorDevice) return "Датчик открытия";
    if (device is MotionSensorDevice) return "Датчик движения";
    if (device is PresenceSensorDevice) return "Датчик присутствия";
    if (device is TempHumiditySensorDevice) return "Датчик климата";
    if (device is LeakSensorDevice) return "Датчик протечки";

    return localizations.unknown;
  }
}
