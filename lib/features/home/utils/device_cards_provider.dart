// lib/features/home/utils/device_cards_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/providers/hubs_provider.dart' as hubsr;
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/providers/selected_hub_provider.dart';
import 'package:ISS/features/devices/device_catalog.dart';
import 'package:ISS/models/hub_models.dart';

final deviceCardsProvider = Provider<List<DeviceCardVm>>((ref) {
  final hubs = ref.watch(hubsr.hubsProvider);
  final live = ref.watch(webSocketNotifierProvider).deviceData;
  final selectedId = ref.watch(selectedHubIdProvider);

  return hubs.maybeWhen(
    data: (list) {
      if (list.isEmpty) return const [];
      final HubObject hub = list.firstWhere(
        (h) => h.commandHubId == selectedId,
        orElse: () => list.first,
      );
      return buildDeviceCatalog(devices: hub.devices, liveById: live);
    },
    orElse: () => const [],
  );
});
