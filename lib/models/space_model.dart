// lib/models/space_model.dart
import 'package:ISS/models/device_models.dart';
import 'package:ISS/utils/device_parser.dart';

class Room {
  final String id;
  final String name;
  final bool isDefault;
  final List<BaseDevice> devices;

  /// Локальный путь к картинке комнаты (для UI)
  final String? localImagePath;

  Room({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.devices = const [],
    this.localImagePath,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    final deviceList =
        (json['devices'] as List? ?? [])
            .map((d) => DeviceParser.parse(d as Map<String, dynamic>))
            .toList();

    return Room(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Room',
      isDefault: json['defaultRoom'] as bool? ?? false,
      devices: deviceList,
      localImagePath: json['localImagePath'] as String?, // может быть null
    );
  }

  Room copyWith({
    String? id,
    String? name,
    bool? isDefault,
    List<BaseDevice>? devices,
    String? localImagePath,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      devices: devices ?? this.devices,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }
}

class Space {
  final String id;
  final String name;
  final List<Room> rooms;

  Space({required this.id, required this.name, required this.rooms});

  factory Space.fromJson(Map<String, dynamic> json) {
    final roomList =
        (json['rooms'] as List? ?? [])
            .map((r) => Room.fromJson(r as Map<String, dynamic>))
            .toList();
    return Space(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Space',
      rooms: roomList,
    );
  }
}
