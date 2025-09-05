import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> prepareUploadImage(
  String originalPath, {
  int targetBytes = 900 * 1024,
}) async {
  try {
    final tmpDir = await getTemporaryDirectory();
    final outNameBase = p.basenameWithoutExtension(originalPath);
    String outPath = p.join(
      tmpDir.path,
      '${outNameBase}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final sizes = <int>[1920, 1600, 1280, 1024, 800];
    final qualities = <int>[85, 75, 65, 50, 40];
    File? lastFile;
    for (final side in sizes) {
      for (final q in qualities) {
        final result = await FlutterImageCompress.compressAndGetFile(
          originalPath,
          outPath,
          format: CompressFormat.jpeg,
          quality: q,
          minWidth: side,
          minHeight: side,
          keepExif: false,
        );
        if (result == null) continue;

        lastFile = File(result.path);
        final len = await lastFile.length();

        if (kDebugMode) {
          print('[IMG] side=$side q=$q => ${len ~/ 1024} KB');
        }
        if (len <= targetBytes) return lastFile.path;
      }
    }
    if (lastFile != null) return lastFile.path;
    return originalPath;
  } catch (e) {
    if (kDebugMode) {
      print('[IMG] compress error: $e');
    }
    return originalPath;
  }
}
