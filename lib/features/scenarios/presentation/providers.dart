// lib/features/scenarios/presentation/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/providers/selected_hub_provider.dart' as hubs;
import '../../scenarios/data/scenarios_repository.dart';
import '../../scenarios/domain/scenario_models.dart';

final scenariosByHubProvider = FutureProvider.autoDispose<List<Scenario>>((
  ref,
) async {
  final hubId = ref.watch(
    hubs.selectedHubIdProvider,
  ); // используй твой провайдер
  if (hubId == null || hubId.isEmpty) return [];
  return ref.read(scenariosRepositoryProvider).listByHub(hubId);
});

final scenarioTemplatesProvider =
    FutureProvider.autoDispose<List<ScenarioTemplate>>((ref) {
      return ref.read(scenariosRepositoryProvider).templates();
    });

final templateByKeyProvider = FutureProvider.family
    .autoDispose<ScenarioTemplate, String>((ref, key) {
      return ref.read(scenariosRepositoryProvider).templateByKey(key);
    });

final devicesByTemplateTypeProvider = FutureProvider.family
    .autoDispose<List<DeviceSummary>, String>((ref, templateType) async {
      final category = mapTemplateTypeToDeviceCategory(templateType);
      return ref.read(scenariosRepositoryProvider).devicesByCategory(category);
    });

/// Контроллер создания из шаблона
class CreateFromTemplateState {
  final List<String> triggerDeviceIds;
  final List<String> actionDeviceIds;
  final AsyncValue<void> status;

  const CreateFromTemplateState({
    this.triggerDeviceIds = const [],
    this.actionDeviceIds = const [],
    this.status = const AsyncData(null),
  });

  CreateFromTemplateState copyWith({
    List<String>? triggerDeviceIds,
    List<String>? actionDeviceIds,
    AsyncValue<void>? status,
  }) => CreateFromTemplateState(
    triggerDeviceIds: triggerDeviceIds ?? this.triggerDeviceIds,
    actionDeviceIds: actionDeviceIds ?? this.actionDeviceIds,
    status: status ?? this.status,
  );
}

class CreateFromTemplateController
    extends StateNotifier<CreateFromTemplateState> {
  final Ref ref;
  final String templateKey;

  CreateFromTemplateController(this.ref, this.templateKey)
    : super(const CreateFromTemplateState());

  void toggleTrigger(String id) {
    final next = [...state.triggerDeviceIds];
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(triggerDeviceIds: next);
  }

  void toggleAction(String id) {
    final next = [...state.actionDeviceIds];
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(actionDeviceIds: next);
  }

  Future<void> submit() async {
    final hubId = ref.read(hubs.selectedHubIdProvider) ?? '';
    if (hubId.isEmpty) throw Exception('Не выбран хаб');
    state = state.copyWith(status: const AsyncLoading());
    try {
      final req = CreateFromTemplateRequest(
        hubId: hubId,
        triggerDevices: state.triggerDeviceIds,
        actionDevices: state.actionDeviceIds,
      );
      await ref
          .read(scenariosRepositoryProvider)
          .createFromTemplate(templateKey, req);
      state = state.copyWith(status: const AsyncData(null));
    } catch (e, s) {
      state = state.copyWith(status: AsyncError(e, s));
    }
  }
}

final createFromTemplateControllerProvider = StateNotifierProvider.autoDispose
    .family<CreateFromTemplateController, CreateFromTemplateState, String>(
      (ref, key) => CreateFromTemplateController(ref, key),
    );
