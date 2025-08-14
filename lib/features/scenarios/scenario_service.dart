import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/features/scenarios/scenario_creation_screen.dart';

final scenarioServiceProvider = Provider<ScenarioService>((ref) {
  return ScenarioService();
});

class ScenarioService {
  Future<bool> saveScenario({
    required String name,
    required String hubId,
    required bool enabled,
    required List<ScenarioTrigger> triggers,
    required List<ScenarioCondition> conditions,
    required List<ScenarioAction> actions,
  }) async {
    try {
      // **ИЗМЕНЕНО: Создаем "плоский" JSON-объект, точно как в вашем примере**
      final Map<String, dynamic> payload = {
        "name": name,
        "hubId":
            hubId, // Добавляем hubId, так как он, скорее всего, нужен серверу
        "enabled": enabled,
        "triggers": triggers.map((t) => t.toJson()).toList(),
        "conditions": conditions.map((c) => c.toJson()).toList(),
        "actions": actions.map((a) => a.toJson()).toList(),
      };

      final response = await dio.post(
        '/scenarios/save',
        data: payload, // Отправляем правильный "плоский" объект
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Scenario saved successfully: ${response.data}');
        return true;
      } else {
        print(
          '❌ Failed to save scenario. Status: ${response.statusCode}, Data: ${response.data}',
        );
        return false;
      }
    } on DioException catch (e) {
      print('❗ Error saving scenario: ${e.response?.data}');
      return false;
    } catch (e) {
      print('❓ Unexpected error: $e');
      return false;
    }
  }
}
