import 'package:dio/dio.dart';
import 'models.dart';

class FamilyGroupService {
  final Dio _dio;
  FamilyGroupService(this._dio);

  Future<List<FamilyGroup>> getGroups() async {
    final res = await _dio.get('/api/v1/family-group');
    final list = (res.data as List).cast<dynamic>();
    return list
        .map((e) => FamilyGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FamilyGroup> getGroup(String groupId) async {
    final res = await _dio.get('/api/v1/family-group/$groupId');
    return FamilyGroup.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> createGroup({
    required String name,
    required List<String> emails,
    required String hubId,
  }) async {
    await _dio.post(
      '/api/v1/family-group/create',
      data: {"name": name, "emails": emails, "hubId": hubId},
    );
  }

  Future<void> addMember(
    String groupId, {
    required String email,
    required FamilyRole role,
  }) async {
    await _dio.post(
      '/api/v1/family-group/add-member/$groupId',
      data: {"email": email, "role": role.name.toUpperCase()},
    );
  }

  Future<void> updateMemberRole(String memberId, FamilyRole role) async {
    await _dio.put(
      '/api/v1/family-group/$memberId/update-member-role',
      data: {"role": role.name.toUpperCase()},
    );
  }

  Future<void> updateGroupName(String groupId, String name) async {
    await _dio.put(
      '/api/v1/family-group/$groupId/update-group-name',
      queryParameters: {"name": name},
    );
  }

  Future<void> transferOwnership(String groupId, String memberId) async {
    await _dio.post(
      '/api/v1/family-group/$groupId/transfer-ownership/$memberId',
    );
  }

  Future<void> attachHub(String groupId, String hubId) async {
    await _dio.post('/api/v1/family-group/$groupId/hub/$hubId/attach');
  }

  Future<void> detachHub(String groupId, String hubId) async {
    await _dio.post('/api/v1/family-group/$groupId/hub/$hubId/dettach');
  }

  Future<void> armSecurity(String groupId, String hubId) async {
    await _dio.post('/api/v1/family-group/$groupId/arm-security/$hubId');
  }

  Future<void> disarmSecurity(String groupId, String hubId) async {
    await _dio.post('/api/v1/family-group/$groupId/disarm-security/$hubId');
  }

  Future<void> deleteMember(String memberId) async {
    await _dio.delete('/api/v1/family-group/$memberId/delete-member');
  }

  Future<void> deleteGroup(String groupId) async {
    await _dio.delete('/api/v1/family-group/$groupId/delete');
  }
}
