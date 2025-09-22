import 'package:equatable/equatable.dart';
import 'package:ISS/models/hub_models.dart';

enum FamilyRole { owner, admin, user, guest }

FamilyRole roleFromString(String? value) {
  switch ((value ?? 'GUEST').toUpperCase()) {
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
  final String name;
  final String? email;
  final FamilyRole role;
  final bool canArmDisarm;
  final String status;
  final String? userId;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.canArmDisarm = false,
    this.status = 'ACTIVE',
    this.userId,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isOwner => role == FamilyRole.owner;

  FamilyMember copyWith({
    FamilyRole? role,
    bool? canArmDisarm,
    String? status,
  }) {
    return FamilyMember(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      canArmDisarm: canArmDisarm ?? this.canArmDisarm,
      status: status ?? this.status,
      userId: userId,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, canArmDisarm, status, userId];

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: (json['id'] ?? json['memberId'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['email'] ?? '—').toString(),
      email: (json['email'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['email'] as String).trim(),
      role: roleFromString(json['role'] as String?),
      canArmDisarm: json['canArmDisarm'] as bool? ?? false,
      status: (json['status'] ?? 'ACTIVE').toString(),
      userId: (json['userId'] ?? json['memberUserId'])?.toString(),
    );
  }
}

class FamilyInvitation extends Equatable {
  final String id;
  final String email;
  final FamilyRole role;
  final String status;
  final DateTime? expiresAt;

  const FamilyInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.expiresAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';

  @override
  List<Object?> get props => [id, email, role, status, expiresAt];

  factory FamilyInvitation.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    final rawExpires = json['expiresAt'];
    if (rawExpires is String && rawExpires.isNotEmpty) {
      exp = DateTime.tryParse(rawExpires);
    }
    return FamilyInvitation(
      id: (json['id'] ?? json['invitationId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: roleFromString(json['role'] as String?),
      status: (json['status'] ?? 'PENDING').toString(),
      expiresAt: exp,
    );
  }
}

class FamilyGroup extends Equatable {
  final String id;
  final String name;
  final List<FamilyMember> members;
  final List<FamilyInvitation> invitations;
  final List<HubObject> hubs;
  final FamilyRole? currentUserRole;
  final bool allowUserDisarm;

  const FamilyGroup({
    required this.id,
    required this.name,
    this.members = const [],
    this.invitations = const [],
    this.hubs = const [],
    this.currentUserRole,
    this.allowUserDisarm = false,
  });

  bool get hasDetails => invitations.isNotEmpty || hubs.isNotEmpty || currentUserRole != null;
  FamilyRole? get roleOrFirstMemberRole => currentUserRole ?? members.firstOrNull?.role;

  FamilyGroup copyWith({
    String? name,
    List<FamilyMember>? members,
    List<FamilyInvitation>? invitations,
    List<HubObject>? hubs,
    FamilyRole? currentUserRole,
    bool? allowUserDisarm,
  }) {
    return FamilyGroup(
      id: id,
      name: name ?? this.name,
      members: members ?? this.members,
      invitations: invitations ?? this.invitations,
      hubs: hubs ?? this.hubs,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      allowUserDisarm: allowUserDisarm ?? this.allowUserDisarm,
    );
  }

  @override
  List<Object?> get props => [id, name, members, invitations, hubs, currentUserRole, allowUserDisarm];

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    final members = ((json['members'] as List?) ?? [])
        .whereType<Map>()
        .map((m) => FamilyMember.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    final invitations = ((json['invitations'] as List?) ?? [])
        .whereType<Map>()
        .map(
          (m) => FamilyInvitation.fromJson(
            Map<String, dynamic>.from(m),
          ),
        )
        .toList();

    final hubs = ((json['hubs'] as List?) ?? [])
        .whereType<Map>()
        .map(
          (m) => HubObject.fromJson(
            Map<String, dynamic>.from(m),
          ),
        )
        .toList();

    final roleRaw = json['currentUserRole'] ?? json['role'];

    return FamilyGroup(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Без названия').toString(),
      members: members,
      invitations: invitations,
      hubs: hubs,
      currentUserRole: roleRaw == null ? null : roleFromString(roleRaw as String?),
      allowUserDisarm: json['allowUserDisarm'] as bool? ?? false,
    );
  }
}

extension FirstOrNullListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : this[0];
}

/// Матрица прав (видимость/доступ к действиям)
class FamilyPermissions {
  static bool canView(FamilyRole role) => true; // Просмотр хабов/устройств

  static bool canControlDevices(FamilyRole role) =>
      role != FamilyRole.guest; // Управление устройствами

  static bool canViewLogs(FamilyRole role) => true; // Просмотр логов/событий

  static bool canArm(FamilyRole role) =>
      role == FamilyRole.owner || role == FamilyRole.admin; // ARM

  static bool canDisarm(FamilyRole role, {bool allowUser = false}) =>
      role == FamilyRole.owner ||
      role == FamilyRole.admin ||
      (allowUser && role == FamilyRole.user);

  static bool canManagePins(FamilyRole role) =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  static bool canManageMembers(FamilyRole role) =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  static bool canChangeRoles(FamilyRole role) =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  static bool canAttachDetachHubs(FamilyRole role) =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  static bool canRenameGroup(FamilyRole role) =>
      role == FamilyRole.owner || role == FamilyRole.admin;

  static bool canDeleteGroup(FamilyRole role) => role == FamilyRole.owner;

  static bool canTransferOwnership(FamilyRole role) => role == FamilyRole.owner;
}
