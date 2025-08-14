// lib/features/rooms/room_image_store.dart

import 'package:shared_preferences/shared_preferences.dart';

class RoomImageStore {
  static const _keyPrefix = 'room_img_';

  static Future<void> save(String roomId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$roomId', path);
  }

  static Future<String?> load(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_keyPrefix$roomId');
  }
}
