// lib/services/location_service.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> restoreBackgroundTrackingIfEnabled() async {
  final core = _LocationCore();
  final enabled = await core.isLocationTrackingEnabled();
  if (enabled) {
    await core.setLocationTrackingEnabled(true);
  }
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool timeout = task.timeout;
  try {
    if (timeout) {
      BackgroundFetch.finish(taskId);
      return;
    }
    final svc = _LocationCore();
    await svc.sendLocationToServer();
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

/// ===== RIVERPOD STATE =====

final locationStateProvider =
    StateNotifierProvider<LocationStateNotifier, LocationState>(
      (ref) => LocationStateNotifier(),
    );

class LocationState {
  final bool trackingEnabled;
  final String? lastError;
  final Position? lastPosition;

  const LocationState({
    required this.trackingEnabled,
    this.lastError,
    this.lastPosition,
  });

  LocationState copyWith({
    bool? trackingEnabled,
    String? lastError,
    Position? lastPosition,
  }) {
    return LocationState(
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      lastError: lastError,
      lastPosition: lastPosition ?? this.lastPosition,
    );
  }
}

class LocationStateNotifier extends StateNotifier<LocationState> {
  LocationStateNotifier() : super(const LocationState(trackingEnabled: false)) {
    _restoreTrackingFlag();
  }

  final _core = _LocationCore();

  Future<void> _restoreTrackingFlag() async {
    final enabled = await _core.isLocationTrackingEnabled();
    state = state.copyWith(trackingEnabled: enabled);
  }

  /// Включить/выключить фоновые отправки. Сохраняется в SharedPreferences.
  Future<void> setLocationTrackingEnabled(bool isEnabled) async {
    try {
      await _core.setLocationTrackingEnabled(isEnabled);
      state = state.copyWith(trackingEnabled: isEnabled, lastError: null);
    } catch (e) {
      state = state.copyWith(lastError: '$e');
    }
  }

  /// Показывает системный диалог (если нужно) и шлёт точку на сервер.
  Future<void> requestPermissionAndSend() async {
    try {
      // 1) Enabled services?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Службы геолокации на устройстве выключены.';
      }

      // 2) permission_handler (Android в т.ч.)
      final pmStatus = await Permission.location.status;
      if (pmStatus.isDenied) {
        final req = await Permission.location.request();
        if (req.isPermanentlyDenied) {
          throw 'Доступ к геолокации запрещён навсегда. Откройте настройки и разрешите доступ.';
        }
      }

      // 3) Geolocator permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Доступ к геолокации запрещён навсегда. Откройте настройки и разрешите доступ.';
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw 'Доступ к геолокации не выдан.';
      }

      // 4) Получаем позицию и отправляем
      final pos = await _core.getCurrentPosition();
      await _core.sendPosition(pos);

      state = state.copyWith(lastPosition: pos, lastError: null);
    } catch (e) {
      state = state.copyWith(lastError: '$e');
      rethrow;
    }
  }
}

/// ===== CORE-ЛОГИКА БЕЗ RIVERPOD =====

class _LocationCore {
  static const _prefsKey = 'isLocationTrackingEnabled';
  static bool _bgConfigured = false;

  Future<void> setLocationTrackingEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, isEnabled);
    if (isEnabled) {
      await _startBackgroundFetch();
    } else {
      await _stopBackgroundFetch();
    }
  }

  Future<bool> isLocationTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> sendLocationToServer() async {
    final pos = await getCurrentPosition();
    await sendPosition(pos);
  }

  Future<void> sendPosition(Position position) async {
    try {
      // ignore: avoid_print
      print(
        '📍 sendPosition: ${position.latitude}, ${position.longitude} @ ${DateTime.now().toIso8601String()}',
      );

      await dio.post(
        '/user/set-location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      // ignore: avoid_print
      print('✅ Геолокация отправлена на сервер');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Ошибка отправки геолокации: $e');
      rethrow;
    }
  }

  Future<void> _startBackgroundFetch() async {
    if (_bgConfigured) return;
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: NetworkType.ANY,
      ),
      (String taskId) async {
        try {
          // ignore: avoid_print
          print('🔔 BackgroundFetch (active) taskId=$taskId');
          await sendLocationToServer();
        } catch (_) {
        } finally {
          BackgroundFetch.finish(taskId);
        }
      },
      (String taskId) async {
        // ignore: avoid_print
        print('⏱️ BackgroundFetch TIMEOUT taskId=$taskId');
        BackgroundFetch.finish(taskId);
      },
    );
    _bgConfigured = true;
    print('▶️ Фоновое отслеживание геолокации запущено (configured).');
  }

  Future<void> _stopBackgroundFetch() async {
    await BackgroundFetch.stop();
    _bgConfigured = false;
    // ignore: avoid_print
    print('⏹️ Фоновое отслеживание геолокации остановлено.');
  }
}
