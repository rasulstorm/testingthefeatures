// lib/features/camera/utils/hls_probe.dart
import 'package:dio/dio.dart';

class HlsProbe {
  final Dio _dio;
  HlsProbe(this._dio);

  Future<bool> checkOnce(String url) async {
    try {
      final r = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ),
      );
      final ok = (r.statusCode ?? 0) >= 200 && (r.statusCode ?? 0) < 300;
      final txt = r.data ?? '';
      return ok && txt.contains('#EXTM3U');
    } catch (_) {
      return false;
    }
  }

  Future<bool> waitReady(
    String url, {
    int tries = 20,
    Duration delay = const Duration(seconds: 1),
  }) async {
    for (var i = 0; i < tries; i++) {
      final ok = await checkOnce(url);
      if (ok) return true;
      await Future.delayed(delay);
    }
    return false;
  }
}
