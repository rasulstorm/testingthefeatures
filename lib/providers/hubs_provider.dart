// lib/providers/hubs_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:flutter/foundation.dart';

// Активная семейная группа (как было)
final activeFamilyGroupIdProvider = StateProvider<String?>((ref) => null);

final hubsProvider = FutureProvider.autoDispose<List<HubObject>>((ref) async {
  final familyGroupId = ref.watch(activeFamilyGroupIdProvider);

  String url;
  Map<String, dynamic>? queryParameters;

  if (familyGroupId != null) {
    debugPrint("HBS PROVIDER: Семейный доступ для группы $familyGroupId");
    url = '/family-group/hubs';
    // при необходимости передай ID группы в path/параметрах
  } else {
    debugPrint("HBS PROVIDER: Обычный режим");
    url = '/mobile/hub/getByUser';
  }

  final response = await dio.get(url, queryParameters: queryParameters);

  // ВАЖНО: backend теперь возвращает голый массив [ ... ].
  // Поддерживаем и старую обёртку { data: [...] } на всякий случай.
  final body = response.data;
  final List list = body is List ? body : (body['data'] as List);

  return list
      .map((e) => HubObject.fromJson(e as Map<String, dynamic>))
      .toList();
});
