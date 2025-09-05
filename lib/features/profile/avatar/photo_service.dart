import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/core/network/dio_provider.dart';

class PhotoEntry {
  final String id;
  final String url;
  final String? name;
  final String? type;

  PhotoEntry({required this.id, required this.url, this.name, this.type});

  factory PhotoEntry.fromJson(Map<String, dynamic> json) => PhotoEntry(
    id: json['id']?.toString() ?? '',
    url: json['url']?.toString() ?? '',
    name: json['name']?.toString(),
    type: json['type']?.toString(),
  );
}

final photoServiceProvider = Provider<PhotoService>((ref) => PhotoService(dio));

class PhotoService {
  PhotoService(this._dio);
  final Dio _dio;

  // --- USER ---
  Future<List<PhotoEntry>> getUserPhotos() async {
    final res = await _dio.get('/photo/user');
    final list = (res.data?['data'] as List?) ?? const [];
    return list
        .map((e) => PhotoEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String normalizeUserPhotoUrl(PhotoEntry p) => _normalizeToApiPhoto(p);

  String? pickBestAvatarUrl(List<PhotoEntry> items) {
    if (items.isEmpty) return null;
    final logo = items.firstWhere(
      (e) => (e.type?.toUpperCase() == 'PROFILE_LOGO'),
      orElse: () => items.first,
    );
    return normalizeUserPhotoUrl(logo);
  }

  // --- HUB ---
  Future<List<PhotoEntry>> getHubPhotos(String hubId) async {
    final res = await _dio.get('/photo/hub/$hubId');
    final list = (res.data?['data'] as List?) ?? const [];
    return list
        .map((e) => PhotoEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String normalizeHubPhotoUrl(PhotoEntry p) => _normalizeToApiPhoto(p);

  String? pickBestHubCoverUrl(List<PhotoEntry> items) {
    if (items.isEmpty) return null;
    // Ищем «крышку» если есть. Поддержим COVER/EXTERIOR как «обложку».
    final preferred = items.firstWhere((e) {
      final t = (e.type ?? '').toUpperCase();
      return t == 'COVER' ||
          t == 'EXTERIOR' ||
          t == 'ИНТЕРЬЕР' ||
          t == 'ЭКСТЕРЬЕР';
    }, orElse: () => items.first);
    return normalizeHubPhotoUrl(preferred);
  }

  // --- helpers ---
  String _normalizeToApiPhoto(PhotoEntry p) {
    final raw = (p.url).trim();
    final base = Uri.parse(
      _dio.options.baseUrl,
    ); // e.g. https://host:443/api/v1
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';

    if (raw.isEmpty) return '$origin/api/v1/photo/${p.id}';

    final uri = Uri.tryParse(raw);
    if (uri == null) return '$origin/api/v1/photo/${p.id}';

    if (!uri.hasScheme) {
      final withSlash = raw.startsWith('/') ? raw : '/$raw';
      return '$origin$withSlash';
    }
    if (!uri.path.contains('/api/')) {
      // сервер может отдавать https://host/{id}, нормализуем к /api/v1/photo/{id}
      return '$origin/api/v1/photo/${p.id}';
    }
    return raw;
  }
}
