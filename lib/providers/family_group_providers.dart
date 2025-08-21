import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';

/// Текущая активная семейная группа (null = обычный режим)
final activeFamilyGroupIdProvider = StateProvider<String?>((ref) => null);

/// Роль текущего пользователя в активной группе
enum FamilyRole { owner, admin, user, guest }

final activeFamilyRoleProvider = StateProvider<FamilyRole?>((ref) => null);

/// Флаг: разрешать DISARM для USER (по умолчанию false; можно переключать из настроек группы)
final allowUserDisarmProvider = StateProvider<bool>((ref) => false);

/// Список семейных групп пользователя
final familyGroupsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final res = await dio.get('/family-group');
  final body = res.data;
  return body is List ? body : (body['data'] as List);
});

/// Хабы/устройства для активной семейной группы
/// Если backend не требует groupId — параметр будет игнорироваться.
final familyHubsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, groupId) async {
      final res = await dio.get(
        '/family-group/hubs',
        queryParameters: {'groupId': groupId},
      );
      final body = res.data;
      return body is List ? body : (body['data'] as List);
    });

/// Матрица прав (только для видимости/активации UI-кнопок)
class FamilyPermissions {
  static bool canView(FamilyRole? r) => true;

  static bool canControlDevices(FamilyRole? r) =>
      r == FamilyRole.owner || r == FamilyRole.admin || r == FamilyRole.user;

  static bool canArm(FamilyRole? r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;

  static bool canDisarm(FamilyRole? r, {required bool allowUser}) =>
      r == FamilyRole.owner ||
      r == FamilyRole.admin ||
      (allowUser && r == FamilyRole.user);

  static bool canManagePins(FamilyRole? r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;

  static bool canManageMembers(FamilyRole? r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;

  static bool canAttachDetachHubs(FamilyRole? r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;

  static bool canRenameGroup(FamilyRole? r) =>
      r == FamilyRole.owner || r == FamilyRole.admin;

  static bool canDeleteGroup(FamilyRole? r) => r == FamilyRole.owner;

  static bool canTransferOwnership(FamilyRole? r) => r == FamilyRole.owner;
}
