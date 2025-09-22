// lib/features/devices/widgets/device_navigator.dart
import 'package:flutter/material.dart';
import 'package:ISS/features/devices/device_catalog.dart';
import 'package:ISS/features/devices/screens/light_detail_screen.dart';
import 'package:ISS/features/devices/screens/curtain_detail_screen.dart';
import 'package:ISS/features/devices/screens/sensor_detail_screen.dart';
import 'package:ISS/features/devices/screens/unknown_detail_screen.dart';

void openDeviceDetails(BuildContext context, DeviceCardVm vm) {
  Widget page;
  switch (vm.kind) {
    case DeviceUiKind.lightDimmer:
      page = LightDetailScreen(vm: vm);
      break;
    case DeviceUiKind.curtain:
      page = CurtainDetailScreen(vm: vm);
      break;
    case DeviceUiKind.sensorMotion:
    case DeviceUiKind.sensorContact:
    case DeviceUiKind.sensorLeak:
    case DeviceUiKind.sensorVibration:
    case DeviceUiKind.climate:
    case DeviceUiKind.relay:
      page = SensorDetailScreen(vm: vm); // универсальная деталка датчиков
      break;
    case DeviceUiKind.unknown:
      page = UnknownDetailScreen(vm: vm);
      break;
  }

  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: page),
    ),
  );
}
