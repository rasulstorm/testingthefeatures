// lib/models/hub_models.dart
import 'package:ISS/models/device_models.dart';

class HubSpaceRef {
  final String id;
  final String name;
  HubSpaceRef({required this.id, required this.name});
  factory HubSpaceRef.fromJson(Map<String, dynamic> json) => HubSpaceRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
}

class HubRoomRef {
  final String id;
  final String name;
  final bool defaultRoom;
  HubRoomRef({required this.id, required this.name, required this.defaultRoom});
  factory HubRoomRef.fromJson(Map<String, dynamic> json) => HubRoomRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    defaultRoom: json['defaultRoom'] as bool? ?? false,
  );
}

class HubGroupRef {
  final String id;
  final String name;
  HubGroupRef({required this.id, required this.name});
  factory HubGroupRef.fromJson(Map<String, dynamic> json) => HubGroupRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
}

class HubObject {
  final String id;
  final String facilityName;
  final String address;
  final String hubNumber;

  /// Ранее это поле называлось commandHubId — оставляем для совместимости UI.
  final String commandHubId;

  final String statusName;
  final String statusNameRus;
  final bool connected; // = isConnected
  final bool onMonitoring; // = isOnMonitoring

  final List<BaseDevice> devices;
  final HubSpaceRef? space;
  final List<HubRoomRef> rooms;

  HubObject({
    required this.id,
    required this.facilityName,
    required this.address,
    required this.hubNumber,
    required this.commandHubId,
    required this.statusName,
    required this.statusNameRus,
    required this.connected,
    required this.devices,
    required this.onMonitoring,
    required this.space,
    required this.rooms,
  });

  factory HubObject.fromJson(Map<String, dynamic> json) {
    // Устройства в ответе «облегчённые» → создаём UnknownDevice,
    // чтобы UI жил до прихода лайв-данных по WebSocket.
    final devicesJson = (json['devices'] as List?) ?? const [];
    final parsedDevices =
        devicesJson.map((d) {
          final m = Map<String, dynamic>.from(d as Map);
          final room = m['room'] as Map<String, dynamic>?;

          final deviceId = (m['id'] ?? '').toString();
          final name = (m['name'] ?? '').toString();
          final title = (m['title'] ?? '').toString();
          final category = (m['deviceCategory'] ?? '').toString();
          final manufacturer = (m['manufacturer'] ?? '').toString();
          final lastUpdate = m['lastUpdate'];
          final friendly = name.isNotEmpty ? name : deviceId;

          final raw =
              <String, dynamic>{
                  'deviceId': deviceId,
                  'name': name,
                  'title': title,
                  'deviceCategory': category,
                  'manufacturer': manufacturer,
                  'lastUpdate': lastUpdate,
                  'room': room,
                  'roomName': room?['roomName'] ?? room?['name'],
                  'controllable': m['controllable'],
                  'type': category.isNotEmpty ? category : (m['type'] ?? ''),
                }
                ..addAll(m)
                ..removeWhere((key, value) => value == null);

          return UnknownDevice(
            id: deviceId,
            friendlyName: friendly,
            model: title.isNotEmpty ? title : category,
            manufacturer: manufacturer,
            linkQuality: 0,
            battery: null,
            rawData: raw,
          );
        }).toList();

    // space
    HubSpaceRef? spaceRef;
    if (json['space'] is Map<String, dynamic>) {
      spaceRef = HubSpaceRef.fromJson(json['space'] as Map<String, dynamic>);
    }

    // rooms
    final roomsJson = (json['rooms'] as List?) ?? const [];
    final roomRefs =
        roomsJson
            .map((r) => HubRoomRef.fromJson(r as Map<String, dynamic>))
            .toList();

    // Выбираем, откуда брать идентификатор команды (hubId предпочтительнее)
    final commandHubId = (json['hubId'] ?? json['hubNumber'] ?? '').toString();

    return HubObject(
      id: (json['id'] ?? '').toString(),
      facilityName: (json['facilityName'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      hubNumber: (json['hubNumber'] ?? '').toString(),
      commandHubId: commandHubId,
      statusName: (json['statusName'] ?? '').toString(),
      statusNameRus: (json['statusNameRus'] ?? '').toString(),
      connected: json['isConnected'] as bool? ?? false, // <—
      onMonitoring: json['isOnMonitoring'] as bool? ?? false, // <—
      devices: parsedDevices,
      space: spaceRef,
      rooms: roomRefs,
    );
  }

  HubObject copyWith({
    String? id,
    String? facilityName,
    String? address,
    String? hubNumber,
    String? commandHubId,
    String? statusName,
    String? statusNameRus,
    bool? connected,
    List<BaseDevice>? devices,
    bool? onMonitoring,
    HubSpaceRef? space,
    List<HubRoomRef>? rooms,
  }) {
    return HubObject(
      id: id ?? this.id,
      facilityName: facilityName ?? this.facilityName,
      address: address ?? this.address,
      hubNumber: hubNumber ?? this.hubNumber,
      commandHubId: commandHubId ?? this.commandHubId,
      statusName: statusName ?? this.statusName,
      statusNameRus: statusNameRus ?? this.statusNameRus,
      connected: connected ?? this.connected,
      devices: devices ?? this.devices,
      onMonitoring: onMonitoring ?? this.onMonitoring,
      space: space ?? this.space,
      rooms: rooms ?? this.rooms,
    );
  }

  factory HubObject.empty() => HubObject(
    id: '',
    facilityName: '',
    address: '',
    hubNumber: '',
    commandHubId: '',
    statusName: '',
    statusNameRus: '',
    connected: false,
    devices: const [],
    onMonitoring: false,
    space: null,
    rooms: const [],
  );
}
