import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/utils/image_prepare.dart';

class UploadedPhoto {
  final String? id;
  final String? url; // может быть пустым — берём через /photo/user
  final String raw;

  UploadedPhoto({this.id, this.url, required this.raw});

  factory UploadedPhoto.fromResponse(dynamic data) {
    final map = (data is Map) ? Map<String, dynamic>.from(data) : {};
    return UploadedPhoto(
      id: map['id']?.toString(),
      url: map['url']?.toString(),
      raw: data.toString(),
    );
  }
}

final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService(dio);
});

class AvatarService {
  AvatarService(this._dio);
  final Dio _dio;

  Future<UploadedPhoto> uploadUserAvatar(
    String filePath, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final preparedPath = await prepareUploadImage(
      filePath,
      targetBytes: 900 * 1024,
    );
    final filename = p.setExtension(p.basename(preparedPath), '.jpg');

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        preparedPath,
        filename: filename,
        contentType: MediaType.parse('image/jpeg'),
      ),
    });

    try {
      final res = await _dio.post(
        '/web/user/upload',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      final data = res.data?['data'] ?? res.data;
      return UploadedPhoto.fromResponse(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('Файл слишком большой. Попробуйте другое фото.');
      }
      rethrow;
    }
  }
}
