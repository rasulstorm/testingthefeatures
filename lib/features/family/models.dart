import 'package:equatable/equatable.dart';

enum FamilyRole { owner, admin, user, guest }

FamilyRole roleFromString(String v) {
  switch (v.toUpperCase()) {
    case 'OWNER':
      return FamilyRole.owner;
    case 'ADMIN':
      return FamilyRole.admin;
    case 'USER':
      return FamilyRole.user;
    case 'GUEST':
      return FamilyRole.guest;
    default:
      return FamilyRole.guest;
  }
}

class FamilyMember extends Equatable {
  final String id; // memberId
  final String email;
  final FamilyRole role;

  const FamilyMember({
    required this.id,
    required this.email,
    required this.role,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
    id: j['id'] as String,
    email: j['email'] as String? ?? '',
    role: roleFromString(j['role'] as String? ?? 'GUEST'),
  );

  @override
  List<Object?> get props => [id, email, role];
}

class FamilyHub extends Equatable {
  final String id; // hubId
  final String facilityName;
  final bool isConnected;

  const FamilyHub({
    required this.id,
    required this.facilityName,
    required this.isConnected,
  });

  factory FamilyHub.fromJson(Map<String, dynamic> j) => FamilyHub(
    id: (j['hubId'] ?? j['id']) as String,
    facilityName: j['facilityName'] as String? ?? '',
    isConnected: j['isConnected'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, facilityName, isConnected];
}

class FamilyGroup extends Equatable {
  final String id; // groupId
  final String name;
  final List<FamilyHub> hubs;
  final List<FamilyMember> members;

  /// Флаг с бэка: разрешить USER выполнять ARM/DISARM (перекрывает матрицу).
  final bool userCanArm;

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.hubs,
    required this.members,
    required this.userCanArm,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> j) {
    final hubs =
        ((j['hubs'] ?? j['data']) as List? ?? [])
            .map((e) => FamilyHub.fromJson(e as Map<String, dynamic>))
            .toList();
    final members =
        (j['members'] as List? ?? [])
            .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
            .toList();
    final flag = j['userCanArm'] as bool? ?? false;
    return FamilyGroup(
      id: j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      hubs: hubs,
      members: members,
      userCanArm: flag,
    );
  }

  @override
  List<Object?> get props => [id, name, hubs, members, userCanArm];
}
