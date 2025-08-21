import 'models.dart';

class PermissionSet {
  final bool canView; // Просмотр хабов/устройств
  final bool canControlDevices; // Управление устройствами (свет/реле)
  final bool canViewLogs; // Просмотр логов/событий
  final bool canArmDisarm; // ARM/DISARM
  final bool canManagePins; // Настройка PIN
  final bool canManageMembers; // Добавить/удалить участников
  final bool canChangeRoles; // Изменить роли
  final bool canAttachDetachHubs; // Привязать/отвязать хабы
  final bool canRenameGroup; // Переименовать группу
  final bool canDeleteGroup; // Удалить группу
  final bool canTransferOwnership; // Передать владение

  const PermissionSet({
    required this.canView,
    required this.canControlDevices,
    required this.canViewLogs,
    required this.canArmDisarm,
    required this.canManagePins,
    required this.canManageMembers,
    required this.canChangeRoles,
    required this.canAttachDetachHubs,
    required this.canRenameGroup,
    required this.canDeleteGroup,
    required this.canTransferOwnership,
  });

  factory PermissionSet.fromRole(
    FamilyRole role, {
    required bool userCanArmFlag,
  }) {
    switch (role) {
      case FamilyRole.owner:
        return const PermissionSet(
          canView: true,
          canControlDevices: true,
          canViewLogs: true,
          canArmDisarm: true,
          canManagePins: true,
          canManageMembers: true,
          canChangeRoles: true,
          canAttachDetachHubs: true,
          canRenameGroup: true,
          canDeleteGroup: true,
          canTransferOwnership: true,
        );
      case FamilyRole.admin:
        return const PermissionSet(
          canView: true,
          canControlDevices: true,
          canViewLogs: true,
          canArmDisarm: true,
          canManagePins: true,
          canManageMembers: true,
          canChangeRoles: true,
          canAttachDetachHubs: true,
          canRenameGroup: true,
          canDeleteGroup: false,
          canTransferOwnership: false,
        );
      case FamilyRole.user:
        return PermissionSet(
          canView: true,
          canControlDevices: true,
          canViewLogs: true,
          canArmDisarm: userCanArmFlag, // по флагу
          canManagePins: false,
          canManageMembers: false,
          canChangeRoles: false,
          canAttachDetachHubs: false,
          canRenameGroup: false,
          canDeleteGroup: false,
          canTransferOwnership: false,
        );
      case FamilyRole.guest:
        return const PermissionSet(
          canView: true,
          canControlDevices: false,
          canViewLogs: true,
          canArmDisarm: false,
          canManagePins: false,
          canManageMembers: false,
          canChangeRoles: false,
          canAttachDetachHubs: false,
          canRenameGroup: false,
          canDeleteGroup: false,
          canTransferOwnership: false,
        );
    }
  }
}
