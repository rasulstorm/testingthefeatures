// lib/features/family_access/family_group_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';

final familyGroupServiceProvider = Provider((ref) => FamilyGroupService());

class FamilyGroupService {
  // Этот метод не меняется, но улучшена обработка ошибок
  Future<void> createGroup({
    required String name,
    required List<String> emails,
    required String hubId,
  }) async {
    try {
      await dio.post(
        '/family-group/create',
        data: {'name': name, 'emails': emails, 'hubId': hubId},
      );
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? 'Error creating family group';
    }
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    try {
      await dio.put(
        '/family-group/$memberId/update-member-role', // Правильный URL
        queryParameters: {
          'role': role.toUpperCase(),
        }, // Правильная передача данных
      );
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? 'Error updating member role';
    }
  }

  // --- ИСПРАВЛЕНО СОГЛАСНО ПРИМЕРУ ---
  // Метод: DELETE
  // URL: /api/v1/family-group/{memberId}/delete
  Future<void> deleteMember({required String memberId}) async {
    try {
      await dio.delete('/family-group/$memberId/delete'); // Правильный URL
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? 'Error deleting member';
    }
  }

  // Этот метод уже был исправлен и соответствует API
  Future<void> addMemberToGroup({
    required String groupId,
    required String email,
    required String role,
  }) async {
    try {
      await dio.post(
        '/family-group/add-member/$groupId',
        data: {"email": email, "role": role.toUpperCase()},
      );
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? 'Failed to add member';
    }
  }
}
