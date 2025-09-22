// lib/features/scenarios/data/scenarios_api.dart
import 'package:dio/dio.dart';
import '../domain/scenario_models.dart';
import '../presentation/device_categories.dart'; // normalizeCategory, allServerCategories

class ScenariosApi {
  final Dio _dio;
  ScenariosApi(this._dio);

  Map<String, dynamic> _asMap(dynamic v) => (v as Map).cast<String, dynamic>();

  // POST /scenarios/save  -> возвращает объект без wrapper'а
  Future<Scenario> save(ScenarioJson json) async {
    final r = await _dio.post('/scenarios/save', data: json.toJson());
    return Scenario.fromJson(_asMap(r.data));
  }

  // PUT /scenarios/{id} -> возвращает объект без wrapper'а
  Future<Scenario> update(String id, ScenarioJson json) async {
    final r = await _dio.put('/scenarios/$id', data: json.toJson());
    return Scenario.fromJson(_asMap(r.data));
  }

  // DELETE /scenarios/delete/{id} -> {code,message} | 200
  Future<void> delete(String id) async {
    await _dio.delete('/scenarios/delete/$id');
  }

  // DELETE /scenarios/delete-by-admin/{id} -> 204 No Content
  Future<void> deleteByAdmin(String id) async {
    await _dio.delete('/scenarios/delete-by-admin/$id');
  }

  // GET /scenarios/{hubId}/by-hub-id -> {code,message,data:[...]}
  Future<List<Scenario>> listByHub(String hubId) async {
    final r = await _dio.get('/scenarios/$hubId/by-hub-id');
    final list = (_asMap(r.data)['data'] as List?) ?? const [];
    return list.map((e) => Scenario.fromJson(_asMap(e))).toList();
  }

  // GET /scenarios/template -> {code,message,data:[...]}
  Future<List<ScenarioTemplate>> templates() async {
    final r = await _dio.get('/scenarios/template');
    final list = (_asMap(r.data)['data'] as List?) ?? const [];
    return list.map((e) => ScenarioTemplate.fromJson(_asMap(e))).toList();
  }

  // GET /scenarios/template/{key} -> либо объект напрямую, либо {code,data:{...}}
  Future<ScenarioTemplate> templateByKey(String key) async {
    try {
      final r = await _dio.get('/scenarios/template/$key');
      final body = _asMap(r.data);
      final map = (body.containsKey('data')) ? _asMap(body['data']) : body;
      return ScenarioTemplate.fromJson(map);
    } on DioException catch (e) {
      final sc = e.response?.statusCode ?? 0;
      // На стейдже могут прислать 409 с телом {code:403,...}. Делаем fallback.
      if (sc == 403 || sc == 409) {
        try {
          final all = await templates();
          final found = all.where((t) => t.key == key).toList();
          if (found.isNotEmpty) return found.first;
        } catch (_) {}
        final body = e.response?.data;
        final msg =
            body is Map && body['message'] is String
                ? body['message'] as String
                : 'Нет доступа к шаблону "$key"';
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          error: msg,
          type: DioExceptionType.badResponse,
        );
      }
      rethrow;
    }
  }

  // POST /scenarios/from-template/{templateKey} -> {code,message,data:{...}}
  Future<CreateFromTemplateResult> createFromTemplate(
    String templateKey,
    CreateFromTemplateRequest body,
  ) async {
    final r = await _dio.post(
      '/scenarios/from-template/$templateKey',
      data: body.toJson(),
    );
    final data = _asMap(_asMap(r.data)['data']);
    return CreateFromTemplateResult.fromJson(data);
  }

  // GET /device/category/{category} -> {code,message,data:[...]}
  Future<List<DeviceSummary>> devicesByCategory(String category) async {
    // 1) нормализуем алиасы (SWITCH/LIGHT/RELAY → LIGHT_SWITCH и т.д.)
    final normalized = normalizeCategory(category);

    // 2) валидация против серверного Enum
    if (!allServerCategories.contains(normalized)) {
      throw ArgumentError(
        'Неподдерживаемая категория "$category" → "$normalized"',
      );
    }

    try {
      final r = await _dio.get('/device/category/$normalized');
      final list = (_asMap(r.data)['data'] as List?) ?? const [];
      return list.map((e) => DeviceSummary.fromJson(_asMap(e))).toList();
    } on DioException catch (e) {
      // Если сервер вернул 500 с текстом про enum-конверсию — пробуем вытащить "value [X]" и ретраим
      final body = e.response?.data;
      if (body is Map && body['message'] is String) {
        final msg = body['message'] as String;
        final m = RegExp(r'value \[([A-Za-z0-9_]+)\]').firstMatch(msg);
        if (m != null) {
          final raw = m.group(1)!;
          final mapped = normalizeCategory(raw);
          if (mapped != normalized && allServerCategories.contains(mapped)) {
            final r2 = await _dio.get('/device/category/$mapped');
            final list2 = (_asMap(r2.data)['data'] as List?) ?? const [];
            return list2.map((e) => DeviceSummary.fromJson(_asMap(e))).toList();
          }
        }
      }
      rethrow;
    }
  }
}
