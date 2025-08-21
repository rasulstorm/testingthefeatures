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
    default:
      return FamilyRole.guest;
  }
}

class FamilyMember extends Equatable {
  final String id;
  final String nameOrEmail;
  final FamilyRole role;
  const FamilyMember({
    required this.id,
    required this.nameOrEmail,
    required this.role,
  });
  @override
  List<Object?> get props => [id, nameOrEmail, role];

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
    id: j['id'] as String,
    nameOrEmail: (j['name'] ?? j['email'] ?? '') as String,
    role: roleFromString(j['role'] as String? ?? 'GUEST'),
  );
}

class FamilyGroup extends Equatable {
  final String id;
  final String name;
  final List<FamilyMember> members;
  const FamilyGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  @override
  List<Object?> get props => [id, name, members];

  factory FamilyGroup.fromJson(Map<String, dynamic> j) => FamilyGroup(
    id: j['id'] as String,
    name: j['name'] as String,
    members:
        ((j['members'] as List?) ?? [])
            .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
            .toList(),
  );
}

/// Матрица прав (видимость/доступ к действиям)
class FamilyPermissions {
  static bool canView(FamilyRole r) => true; // Просмотр хабов/устройств
  static bool canControlDevices(FamilyRole r) =>
      r != FamilyRole.guest; // Управление устройствами
  static bool canViewLogs(FamilyRole r) => true; // Просмотр логов/событий
  static bool canArm(FamilyRole r) =>
      r == FamilyRole.owner || r == FamilyRole.admin; // ARM
  static bool canDisarm(FamilyRole r, {bool allowUser = false}) =>
      r == FamilyRole.owner ||
      r == FamilyRole.admin ||
      (allowUser && r == FamilyRole.user);
  static bool canManagePins(FamilyRole r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;
  static bool canManageMembers(FamilyRole r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;
  static bool canChangeRoles(FamilyRole r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;
  static bool canAttachDetachHubs(FamilyRole r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;
  static bool canRenameGroup(FamilyRole r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;
  static bool canDeleteGroup(FamilyRole r) => r == FamilyRole.owner;
  static bool canTransferOwnership(FamilyRole r) => r == FamilyRole.owner;
}
