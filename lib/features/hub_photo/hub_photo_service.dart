import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';

class HubPhotoItem {
  final String id;
  final String url;
  final String? name;
  final String? type;

  HubPhotoItem({required this.id, required this.url, this.name, this.type});

  factory HubPhotoItem.fromJson(Map<String, dynamic> json) {
    return HubPhotoItem(
      id: json['id']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      name: json['name'] as String?,
      type: json['type']?.toString(),
    );
  }
}

class HubPhotoService {
  const HubPhotoService();

  /// GET /api/v1/photo/hub/{hubId}
  Future<List<HubPhotoItem>> getHubPhotos(String hubId) async {
    final res = await dio.get('/photo/hub/$hubId');
    final list = (res.data?['data'] as List?) ?? const [];
    return list
        .map((e) => HubPhotoItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /api/v1/hub/upload (multipart)
  ///
  /// required fields: file, hubId (UUID), type, name
  Future<HubPhotoItem?> uploadHubPhoto({
    required String hubUuid,
    required File file,
    String type = 'ROOM',
    String name = 'Главная обложка',
  }) async {
    final form = FormData.fromMap({
      'hubId': hubUuid,
      'type': type,
      'name': name,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    });

    final res = await dio.post('/hub/upload', data: form);
    // многие бэки возвращают только "success", поэтому на всякий — перечитаем список
    try {
      final fromUpload = res.data?['data'];
      if (fromUpload is Map) {
        return HubPhotoItem.fromJson(Map<String, dynamic>.from(fromUpload));
      }
    } catch (_) {}
    final list = await getHubPhotos(hubUuid);
    return list.isNotEmpty ? list.first : null;
  }
}
