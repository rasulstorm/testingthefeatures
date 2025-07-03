// lib/models/hub_models.dart

class Device {
  final String id;
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime lastUpdate;
  final Space? space;
  final Group? group;
  final Room? room;

  Device({
    required this.id,
    required this.name,
    required this.parameters,
    required this.lastUpdate,
    this.space,
    this.group,
    this.room,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      lastUpdate: DateTime.tryParse(json['lastUpdate'] as String? ?? '') ?? DateTime.now(),
      space: json['space'] != null ? Space.fromJson(json['space']) : null,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
    );
  }
}

class Space {
  final String id;
  final String name;

  Space({required this.id, required this.name});

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class Room {
  final String id;
  final String name;
  final bool defaultRoom;

  Room({required this.id, required this.name, required this.defaultRoom});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      defaultRoom: json['defaultRoom'] as bool? ?? false,
    );
  }
}

class Group {
  final String id;
  final String name;

  Group({required this.id, required this.name});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class HubObject {
  final String id; // Это ID хаба, вероятно, GUID '3fa85f64...'
  final String facilityName;
  final String address;
  final String hubNumber; // Это '3C40FR'
  final String commandHubId; // <-- НОВОЕ ПОЛЕ для 'isshub_ccc2ddbc'
  final String statusName;
  final String statusNameRus;
  final bool connected;
  final List<Device> devices;

  HubObject({
    required this.id,
    required this.facilityName,
    required this.address,
    required this.hubNumber,
    required this.commandHubId, // <-- ДОБАВЛЕНО
    required this.statusName,
    required this.statusNameRus,
    required this.connected,
    required this.devices,
  });

  factory HubObject.fromJson(Map<String, dynamic> json) {
    var devicesList = <Device>[];
    if (json['devices'] != null) {
      devicesList = (json['devices'] as List)
          .map((i) => Device.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return HubObject(
      id: json['id'] as String? ?? '',
      facilityName: json['facilityName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      hubNumber: json['hubNumber'] as String? ?? '',
      commandHubId: json['hubId'] as String? ?? '', // <-- ПАРСИМ ИЗ JSON 'hubId'
      statusName: json['statusName'] as String? ?? '',
      statusNameRus: json['statusNameRus'] as String? ?? '',
      connected: json['connected'] as bool? ?? false,
      devices: devicesList,
    );
  }
}