import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/models/hub_models.dart';

/// Если включён "семейный режим" (выбрана конкретная группа), можно продолжать
/// использовать этот провайдер как раньше (если нужно).
final activeFamilyGroupIdProvider = StateProvider<String?>((ref) => null);

/// Обычные (личные) хабы пользователя
final hubsProvider = FutureProvider.autoDispose<List<HubObject>>((ref) async {
  debugPrint("HUBS: обычный режим /mobile/hub/getByUser");
  final resp = await dio.get('/mobile/hub/getByUser');
  final body = resp.data;
  final List list = body is List ? body : (body['data'] as List);
  return list
      .map((e) => HubObject.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Все семейные хабы текущего пользователя (агрегация по всем его группам)
final familyAllHubsProvider = FutureProvider.autoDispose<List<HubObject>>((
  ref,
) async {
  debugPrint("HUBS: семейный фоллбэк /family-group/hubs");
  final resp = await dio.get('/family-group/hubs');
  final body = resp.data;
  final List list = body is List ? body : (body['data'] as List);
  return list
      .map((e) => HubObject.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Композит для домашнего экрана: сначала берём свои хабы,
/// если пусто — берём семейные.
final homeHubsProvider = FutureProvider.autoDispose<List<HubObject>>((
  ref,
) async {
  final own = await ref.watch(hubsProvider.future);
  if (own.isNotEmpty) return own;
  final fam = await ref.watch(familyAllHubsProvider.future);
  return fam;
});
