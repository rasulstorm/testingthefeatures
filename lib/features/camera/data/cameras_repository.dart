import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/camera_models.dart';
import '../utils/hls_probe.dart';
import 'cameras_api.dart';
import 'api_providers.dart'; // <— вот отсюда берём providers

class CamerasRepository {
  final CamerasApi api;
  final HlsProbe probe;
  CamerasRepository({required this.api, required this.probe});

  // CRUD и действия
  Future<List<Camera>> listMine() => api.byUser();
  Future<Camera> getById(String id) => api.getById(id);
  Future<Camera> create(CameraRequest req) => api.create(req);
  Future<Camera> update(String id, CameraRequest req) => api.update(id, req);
  Future<void> delete(String id) => api.delete(id);
  Future<Camera> activate(String id) => api.activate(id);
  Future<Camera> deactivate(String id) => api.deactivate(id);

  /// LIVE: ждём, пока плейлист станет доступен (лечит 404/пусто)
  Future<String> ensureLiveHlsUrl(String cameraId) async {
    Camera cam = await api.getById(cameraId);
    if (cam.status != CameraStatus.ENABLED) {
      cam = await api.activate(cameraId);
      cam = await api.getById(cameraId);
    }
    final url = cam.hlsUrl;
    if (url == null || url.isEmpty) {
      throw Exception('LIVE HLS URL пустой');
    }
    final ok = await probe.waitReady(
      url,
      tries: 30,
      delay: const Duration(seconds: 1),
    );
    if (!ok) throw Exception('LIVE: плейлист не появился (404/пусто)');
    return url;
  }

  /// VOD: проверяем доступность архивного плейлиста (если есть)
  Future<String?> ensureVodPlaylistUrl(String cameraId) async {
    final cam = await api.getById(cameraId);
    final url = cam.videoPlaylistUrl; // поле должно быть в модели
    if (url == null || url.isEmpty) return null;
    final ok = await probe.waitReady(
      url,
      tries: 10,
      delay: const Duration(seconds: 1),
    );
    if (!ok) {
      throw Exception('Архивный плейлист не найден/пуст — попробуй позже');
    }
    return url;
  }
}

/// Провайдер репозитория
final camerasRepositoryProvider = Provider<CamerasRepository>((ref) {
  final api = ref.read(camerasApiProvider);
  final probe = ref.read(hlsProbeProvider);
  return CamerasRepository(api: api, probe: probe);
});
