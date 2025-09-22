import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/models/family_group_models.dart';
import 'package:ISS/models/hub_models.dart';

class FamilyGroupService {
  /// Получить все группы пользователя
  Future<List<FamilyGroup>> getAllGroups() async {
    final response = await dio.get('/family-group');
    final data = response.data;
    final List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      rawList = inner is List ? inner : const [];
    } else {
      rawList = const [];
    }

    return rawList
        .whereType<Map>()
        .map((e) => FamilyGroup.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Данные группы по id
  Future<FamilyGroup> getGroupById(String groupId) async {
    final response = await dio.get('/family-group/$groupId');
    final data = response.data;
    Map<String, dynamic> payload = const {};
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(inner);
      } else if (inner is List && inner.isNotEmpty && inner.first is Map) {
        payload = Map<String, dynamic>.from(inner.first as Map);
      } else {
        payload = Map<String, dynamic>.from(data);
      }
    }
    return FamilyGroup.fromJson(payload);
  }

  /// Хабы для всех групп (упрощённо для «семейного режима»)
  Future<List<HubObject>> getHubsForGroups({String? groupId}) async {
    final response = await dio.get(
      '/family-group/hubs',
      queryParameters: groupId == null ? null : {'groupId': groupId},
    );
    final data = response.data;
    final List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      final inner = data['data'];
      rawList = inner is List ? inner : const [];
    } else {
      rawList = const [];
    }

    return rawList
        .whereType<Map>()
        .map((e) => HubObject.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createGroup({
    required String name,
    List<String> emails = const [],
    String? hubId,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'emails': emails,
      if (hubId != null && hubId.isNotEmpty) 'hubId': hubId,
    };
    await dio.post('/family-group/create', data: payload);
  }

  Future<void> addMember(
    String groupId, {
    required String email,
    required FamilyRole role,
    bool? canArmDisarm,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      'role': role.name.toUpperCase(),
      if (canArmDisarm != null) 'canArmDisarm': canArmDisarm,
    };
    await dio.post('/family-group/add-member/$groupId', data: payload);
  }

  Future<void> deleteMember(String memberId) async {
    await dio.delete('/family-group/$memberId/delete-member');
  }

  Future<void> updateMemberRole(
    String memberId,
    FamilyRole role, {
    bool? canArmDisarm,
  }) async {
    final query = <String, dynamic>{'role': role.name.toUpperCase()};
    if (canArmDisarm != null) {
      query['canArmDisarm'] = canArmDisarm;
    }
    await dio.put(
      '/family-group/$memberId/update-member-role',
      queryParameters: query,
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

  Future<void> arm(String groupId, String hubId, {String? pin}) async {
    await dio.post(
      '/family-group/$groupId/arm-security/$hubId',
      data: pin == null ? null : {'pin': pin},
    );
  }

  Future<void> disarm(String groupId, String hubId, {String? pin}) async {
    await dio.post(
      '/family-group/$groupId/disarm-security/$hubId',
      data: pin == null ? null : {'pin': pin},
    );
  }

}

final familyGroupService = FamilyGroupService();
