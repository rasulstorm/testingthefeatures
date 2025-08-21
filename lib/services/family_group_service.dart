import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/models/family_group_models.dart';

class FamilyGroupService {
  /// Получить все группы пользователя
  Future<List<FamilyGroup>> getAllGroups() async {
    final r = await dio.get('/family-group');
    final list = (r.data['data'] as List?) ?? [];
    return list
        .map((e) => FamilyGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Данные группы по id
  Future<FamilyGroup> getGroupById(String groupId) async {
    final r = await dio.get('/family-group/$groupId');
    return FamilyGroup.fromJson((r.data['data'] as Map<String, dynamic>));
  }

  /// Хабы для всех групп (упрощённо для «семейного режима»)
  Future<List<dynamic>> getHubsForGroups() async {
    final r = await dio.get('/family-group/hubs');
    return (r.data['data'] as List? ?? []);
  }

  Future<void> createGroup({
    required String name,
    required List<String> emails,
    required String hubId,
  }) async {
    await dio.post(
      '/family-group/create',
      data: {"name": name, "emails": emails, "hubId": hubId},
    );
  }

  Future<void> addMember(
    String groupId, {
    required String email,
    required FamilyRole role,
  }) async {
    await dio.post(
      '/family-group/add-member/$groupId',
      data: {"email": email, "role": role.name.toUpperCase()},
    );
  }

  Future<void> deleteMember(String memberId) async {
    await dio.delete('/family-group/$memberId/delete-member');
  }

  Future<void> updateMemberRole(String memberId, FamilyRole role) async {
    await dio.put(
      '/family-group/$memberId/update-member-role',
      queryParameters: {'role': role.name.toUpperCase()},
    );
  }

  Future<void> transferOwnership(String groupId, String memberId) async {
    await dio.post('/family-group/$groupId/transfer-ownership/$memberId');
  }

  Future<void> renameGroup(String groupId, String newName) async {
    await dio.put(
      '/family-group/$groupId/update-group-name',
      queryParameters: {'name': newName},
    );
  }

  Future<void> attachHub(String groupId, String hubId) async {
    await dio.post('/family-group/$groupId/hub/$hubId/attach');
  }

  Future<void> detachHub(String groupId, String hubId) async {
    await dio.post('/family-group/$groupId/hub/$hubId/dettach');
  }

  Future<void> arm(String groupId, String hubId) async {
    await dio.post('/family-group/$groupId/arm-security/$hubId');
  }

  Future<void> disarm(String groupId, String hubId) async {
    await dio.post('/family-group/$groupId/disarm-security/$hubId');
  }
}

final familyGroupService = FamilyGroupService();
