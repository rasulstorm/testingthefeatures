// lib/providers/selected_hub_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/models/hub_models.dart';

/// Текущий выбранный hub ID (commandHubId)
final selectedHubIdProvider = StateProvider<String?>((ref) => null);

/// Объект текущего хаба на основе selectedHubIdProvider
final currentHubProvider = Provider<HubObject?>((ref) {
  final hubsAsync = ref.watch(hubsProvider);
  final selectedId = ref.watch(selectedHubIdProvider);
  return hubsAsync.maybeWhen(
    data: (hubs) {
      if (hubs.isEmpty) return null;
      if (selectedId == null) return hubs.first;
      return hubs.firstWhere(
        (h) => h.commandHubId == selectedId,
        orElse: () => hubs.first,
      );
    },
    orElse: () => null,
  );
});
