// lib/features/rooms/rooms_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/models/space_model.dart';
import 'package:ISS/utils/device_parser.dart';
import 'package:ISS/features/rooms/rooms_service.dart';

/// Единственное пространство (Space) для хаба из getObjects,
/// + список комнат также из getObjects.
/// Тут мы преобразуем HubObject.space + HubObject.rooms -> Space (UI-модель)
final spaceForHubProvider = Provider.autoDispose.family<Space?, String>((
  ref,
  hubCommandId,
) {
  final hubs = ref.watch(hubsProvider).asData?.value ?? [];
  if (hubs.isEmpty) return null;

  final hub = hubs.firstWhere(
    (h) => h.commandHubId == hubCommandId,
    orElse: () => hubs.first,
  );

  if (hub.space == null || hub.space!.id.isEmpty) return null;

  final spaceId = hub.space!.id;
  final spaceName = hub.space!.name;

  final roomList =
      hub.rooms
          .map(
            (r) => Room(
              id: r.id,
              name: r.name,
              isDefault: r.defaultRoom,
              devices: const [],
              localImagePath: null,
            ),
          )
          .toList();

  return Space(id: spaceId, name: spaceName, rooms: roomList);
});

/// Устройства в комнате — грузим из бекенда (roomId -> /device/{roomId}/find-by-room)
final roomDevicesProvider = FutureProvider.autoDispose
    .family<List<BaseDevice>, String>((ref, roomId) async {
      if (roomId.isEmpty) return [];
      final service = ref.read(roomsServiceProvider);
      final list = await service.getDevicesByRoom(roomId);
      return list.map((d) => DeviceParser.parse(d)).toList();
    });

/// Нераспределённые устройства хаба — берём прямо из getObjects (room == null)
final unassignedDevicesProvider = Provider.autoDispose
    .family<List<BaseDevice>, String>((ref, hubCommandId) {
      final hubs = ref.watch(hubsProvider).asData?.value ?? [];
      if (hubs.isEmpty) return [];

      final currentHub = hubs.firstWhere(
        (h) => h.commandHubId == hubCommandId,
        orElse: () => hubs.first,
      );

      return currentHub.devices.where((d) {
        final roomField = d.rawData['room'];
        return roomField == null;
      }).toList();
    });
