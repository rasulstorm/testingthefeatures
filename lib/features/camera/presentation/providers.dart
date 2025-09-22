import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera_models.dart';
import '../data/cameras_repository.dart';

// Список камер
final camerasProvider = FutureProvider<List<Camera>>((ref) async {
  return ref.read(camerasRepositoryProvider).listMine();
});

// Камера по id
final cameraByIdProvider = FutureProvider.family<Camera, String>((ref, id) {
  return ref.read(camerasRepositoryProvider).getById(id);
});

// Режим проигрывания на экране (на камеру)
enum StreamMode { live, vod }

final cameraStreamModeProvider = StateProvider.family<StreamMode, String>(
  (ref, id) => StreamMode.live,
);

// Готовый LIVE URL (ожидает появления плейлиста без 404)
final liveHlsUrlProvider = FutureProvider.family<String, String>((ref, id) {
  return ref.read(camerasRepositoryProvider).ensureLiveHlsUrl(id);
});

// Готовый VOD URL (проверяем доступность архива)
final vodPlaylistUrlProvider = FutureProvider.family<String?, String>((
  ref,
  id,
) async {
  return ref.read(camerasRepositoryProvider).ensureVodPlaylistUrl(id);
});
