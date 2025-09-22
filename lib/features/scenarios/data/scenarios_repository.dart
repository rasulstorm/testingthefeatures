// lib/features/scenarios/data/scenarios_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart'
    show dio; // <-- берём твой глобальный dio
import '../domain/scenario_models.dart';
import 'scenarios_api.dart';

final scenariosApiProvider = Provider<ScenariosApi>((ref) {
  return ScenariosApi(dio);
});

final scenariosRepositoryProvider = Provider<ScenariosRepository>((ref) {
  return ScenariosRepository(ref.read(scenariosApiProvider));
});

class ScenariosRepository {
  final ScenariosApi _api;
  ScenariosRepository(this._api);

  Future<List<Scenario>> listByHub(String hubId) => _api.listByHub(hubId);
  Future<List<ScenarioTemplate>> templates() => _api.templates();
  Future<ScenarioTemplate> templateByKey(String key) => _api.templateByKey(key);
  Future<CreateFromTemplateResult> createFromTemplate(
    String key,
    CreateFromTemplateRequest body,
  ) => _api.createFromTemplate(key, body);

  Future<Scenario> save(ScenarioJson json) => _api.save(json);
  Future<Scenario> update(String id, ScenarioJson json) =>
      _api.update(id, json);
  Future<void> delete(String id) => _api.delete(id);
  Future<void> deleteByAdmin(String id) => _api.deleteByAdmin(id);

  Future<List<DeviceSummary>> devicesByCategory(String category) =>
      _api.devicesByCategory(category);
}
