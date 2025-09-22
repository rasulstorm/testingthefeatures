// lib/features/hub_photo/hub_photo_controller.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';

class HubPhotoState {
  final bool loading;
  final String? url; // уже с cache-bust
  final String? rawUrl; // как пришла с бэка
  final String? error;

  const HubPhotoState({
    this.loading = false,
    this.url,
    this.rawUrl,
    this.error,
  });

  HubPhotoState copyWith({
    bool? loading,
    String? url,
    String? rawUrl,
    String? error,
  }) {
    return HubPhotoState(
      loading: loading ?? this.loading,
      url: url ?? this.url,
      rawUrl: rawUrl ?? this.rawUrl,
      error: error,
    );
  }
}

final hubPhotoControllerProvider =
    StateNotifierProvider<HubPhotoController, HubPhotoState>((ref) {
      return HubPhotoController(ref);
    });

class HubPhotoController extends StateNotifier<HubPhotoState> {
  HubPhotoController(this._ref) : super(const HubPhotoState());

  final Ref _ref;

  static const Set<String> _allowedTypes = {'HUB', 'ROOM', 'PROFILE_LOGO'};

  String _normalizeType(String type) {
    final t = type.trim().toUpperCase();
    return _allowedTypes.contains(t) ? t : 'HUB';
  }

  String _bust(String url) {
    final sep = url.contains('?') ? '&' : '?';
    return '$url${sep}t=${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Загрузить текущую фотку хаба (первая из списка — достаточно для «обложки»)
  Future<void> loadForHub(String hubUuid) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final res = await dio.get('/photo/hub/$hubUuid');
      final data = res.data;
      final list =
          (data is Map && data['data'] is List)
              ? data['data'] as List
              : const [];
      if (list.isEmpty) {
        state = state.copyWith(loading: false, url: null, rawUrl: null);
        return;
      }

      // Предпочитаем ROOM/HUB, затем остальные
      Map? best = list.cast<Map>().firstWhere(
        (m) => (m['type']?.toString().toUpperCase() ?? '') == 'ROOM',
        orElse: () => {},
      );
      if (best.isEmpty) {
        best = list.cast<Map>().firstWhere(
          (m) => (m['type']?.toString().toUpperCase() ?? '') == 'HUB',
          orElse: () => {},
        );
      }
      if (best.isEmpty) {
        best = list.cast<Map>().first;
      }

      final url = best['url']?.toString();
      if (url == null || url.isEmpty) {
        state = state.copyWith(loading: false, url: null, rawUrl: null);
        return;
      }

      state = state.copyWith(loading: false, rawUrl: url, url: _bust(url));
    } catch (e, s) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('loadForHub error: $e\n$s');
      }
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// Аплоад фото для хаба. Авто-нормализация типа и фолбэк, если у бэка нет такого enum.
  Future<bool> uploadForHub({
    required String hubUuid,
    required File file,
    String type = 'ROOM',
    String name = 'Cover',
  }) async {
    state = state.copyWith(loading: true, error: null);
    final normalized = _normalizeType(type);

    Future<Response> send(String t) async {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'hubId': hubUuid,
        'type': t, // ВАЖНО: ЕNUM В ВЕРХНЕМ РЕГИСТРЕ
        'name': name,
      });
      return dio.post('/hub/upload', data: form);
    }

    try {
      Response res;
      try {
        res = await send(normalized);
      } on DioException catch (e) {
        final msg = e.response?.data?.toString() ?? e.message ?? '';
        // Если бэк говорит, что такого enum нет — попробуем нейтральный тип HUB
        final looksLikeEnumError =
            msg.contains('No enum constant') || msg.contains('enum');
        if (looksLikeEnumError && normalized != 'HUB') {
          res = await send('HUB');
        } else {
          rethrow;
        }
      }

      // после аплоада — обновим список, чтобы сразу показать новую фотку
      await loadForHub(hubUuid);
      state = state.copyWith(loading: false);
      return true;
    } catch (e, s) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('uploadForHub error: $e\n$s');
      }
      state = state.copyWith(loading: false, error: e.toString());
      return false;
    }
  }
}
