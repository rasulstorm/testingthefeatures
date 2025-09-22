// lib/features/home/home_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/l10n/app_localizations.dart';

import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/providers/selected_hub_provider.dart';
import 'package:ISS/providers/hubs_provider.dart' as hubsr;
import 'package:ISS/services/hub_service.dart';
import 'package:ISS/features/hub_photo/hub_photo_controller.dart';

import 'package:ISS/models/device_models.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/utils/device_parser.dart';

class HomeController {
  final WidgetRef ref;
  final BuildContext context;

  HomeController({required this.ref, required this.context});

  // -------------------- SnackBars --------------------
  void _showErrorSnackBar(String message, [dynamic error]) {
    final text = '$message${error != null ? ' : $error' : ''}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // -------------------- Live normalize & merge --------------------
  /// Приводим карту live-данных к виду, где ключом всегда может быть deviceId
  Map<String, Map<String, dynamic>> _normalizeLiveMap(
    Map<String, Map<String, dynamic>> live,
  ) {
    final out = <String, Map<String, dynamic>>{};
    live.forEach((key, value) {
      // сохраняем оригинальный ключ как есть
      out[key] = value;

      // добавляем алиасы по deviceId/id/...
      String? did =
          (value['deviceId'] ??
                  value['device_id'] ??
                  value['id'] ??
                  value['devId'])
              ?.toString();

      if (did != null && did.isNotEmpty) {
        out[did] = value;
      }
    });
    return out;
  }

  BaseDevice mergeLive(
    BaseDevice device,
    Map<String, Map<String, dynamic>> liveMap,
  ) {
    if (liveMap.isEmpty) return device;

    final normalized = _normalizeLiveMap(liveMap);

    // 1) всегда сначала ищем по device.id
    final byId = normalized[device.id];
    if (byId != null) {
      return DeviceParser.parse({...device.rawData, ...byId});
    }

    // 2) редкий фолбэк — friendlyName (если бекенд шлёт только имя)
    final fn = (device.friendlyName ?? '').trim();
    if (fn.isNotEmpty && normalized.containsKey(fn)) {
      final byFn = normalized[fn]!;
      return DeviceParser.parse({...device.rawData, ...byFn});
    }

    return device;
  }

  // -------------------- Hub WS --------------------
  void _shareHubDevicesOverWs(HubObject hub) {
    final ws = ref.read(webSocketNotifierProvider.notifier);
    final sent = <String>{};

    for (final d in hub.devices) {
      // Отправляем ИД как основной ключ
      if (d.id.isNotEmpty && sent.add(d.id)) {
        ws.sendShareDeviceData(hub.commandHubId, d.id);
      }
      // И дополнительно публикация по friendlyName (на случай старых хабов)
      final fn = (d.friendlyName ?? '').trim();
      if (fn.isNotEmpty && sent.add(fn)) {
        ws.sendShareDeviceData(hub.commandHubId, fn);
      }
    }
  }

  Future<void> onHubChanged(HubObject newHub) async {
    ref.read(selectedHubIdProvider.notifier).state = newHub.commandHubId;
    final ws = ref.read(webSocketNotifierProvider.notifier);
    ws.disconnect();
    ws.connect(newHub.commandHubId);
    _shareHubDevicesOverWs(newHub);
    await ref.read(hubPhotoControllerProvider.notifier).loadForHub(newHub.id);
  }

  Future<void> refreshHubs(HubObject? selected) async {
    await ref.refresh(hubsr.hubsProvider.future);
    if (selected != null) {
      await ref
          .read(hubPhotoControllerProvider.notifier)
          .loadForHub(selected.id);
    }
  }

  void connectInitialHub() {
    final savedHubId = ref.read(selectedHubIdProvider);
    if (savedHubId != null && savedHubId.isNotEmpty) {
      ref.read(webSocketNotifierProvider.notifier).connect(savedHubId);
    }
  }

  // -------------------- Security --------------------
  Future<void> armSecurity(
    HubObject hub, {
    required VoidCallback onStart,
    required VoidCallback onFinally,
    required VoidCallback clearOverride,
    required VoidCallback setOverrideOnError,
  }) async {
    final loc = AppLocalizations.of(context);
    onStart();
    try {
      await dio.post('/hub/${hub.commandHubId}/arm-security');
      _showSuccessSnackBar(loc.securityArmed);
      await refreshHubs(hub);
      clearOverride();
    } catch (e) {
      setOverrideOnError();
      _handleApiError(e, fallback: 'Не удалось поставить на охрану');
    } finally {
      onFinally();
    }
  }

  Future<void> disarmSecurity(
    HubObject hub, {
    required String pin,
    required VoidCallback onStart,
    required VoidCallback onFinally,
    required VoidCallback clearOverride,
    required VoidCallback setOverrideOnError,
  }) async {
    final loc = AppLocalizations.of(context);
    onStart();
    try {
      await dio.post(
        '/hub/${hub.commandHubId}/disarm-security',
        data: {'pin': pin},
      );
      _showSuccessSnackBar(loc.securityDisarmed);
      await refreshHubs(hub);
      clearOverride();
    } catch (e) {
      setOverrideOnError();
      _handleApiError(e, fallback: 'Не удалось снять с охраны');
    } finally {
      onFinally();
    }
  }

  // -------------------- PINs --------------------
  Future<void> setPins(
    HubObject hub, {
    required String disarmPin,
    required String duressPin,
  }) async {
    try {
      await dio.post(
        '/hub/${hub.commandHubId}/set-pins',
        data: {'disarmPin': disarmPin, 'duressPin': duressPin},
      );
      _showSuccessSnackBar('PIN-коды сохранены');
    } catch (e) {
      _handleApiError(e, fallback: 'Не удалось сохранить PIN-коды');
    }
  }

  Future<void> changeDisarmPin(
    HubObject hub, {
    required String oldPin,
    required String newPin,
  }) async {
    try {
      await dio.put(
        '/hub/${hub.commandHubId}/new-disarm-pin',
        data: {'oldPin': oldPin, 'newPin': newPin},
      );
      _showSuccessSnackBar('PIN изменён');
    } catch (e) {
      _handleApiError(e, fallback: 'Не удалось изменить PIN');
    }
  }

  Future<void> changeDuressPin(
    HubObject hub, {
    required String oldPin,
    required String newPin,
  }) async {
    try {
      await dio.put(
        '/hub/${hub.commandHubId}/new-duress-pin',
        data: {'oldPin': oldPin, 'newPin': newPin},
      );
      _showSuccessSnackBar('Тревожный PIN изменён');
    } catch (e) {
      _handleApiError(e, fallback: 'Не удалось изменить тревожный PIN');
    }
  }

  // -------------------- Hub actions --------------------
  Future<void> startPairing(String hubId) async {
    final loc = AppLocalizations.of(context);
    final service = ref.read(hubServiceProvider);
    final ok = await service.startPairing(hubId);
    ok
        ? _showSuccessSnackBar(loc.pairingStartedSuccess)
        : _showErrorSnackBar(loc.pairingStartedFailed);
  }

  Future<void> detachHub(HubObject hub) async {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await dio.post('/mobile/hub/${hub.id}/detach');
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessSnackBar(loc.hubDetachedSuccess);
      await refreshHubs(null);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar(loc.hubDetachedFailed, e);
    }
  }

  Future<void> uploadHubPhoto({
    required HubObject hub,
    required File file,
  }) async {
    final ok = await ref
        .read(hubPhotoControllerProvider.notifier)
        .uploadForHub(
          hubUuid: hub.id,
          file: file,
          type: 'ROOM',
          name: 'Главная обложка',
        );
    ok
        ? _showSuccessSnackBar('Фото обновлено')
        : _showErrorSnackBar('Не удалось загрузить фото');
  }

  // -------------------- Errors --------------------
  void _handleApiError(Object error, {required String fallback}) {
    try {
      final status = (error as dynamic).response?.statusCode as int?;
      String msg = fallback;
      switch (status) {
        case 400:
          msg = 'Некорректный запрос';
          break;
        case 401:
          msg = 'Не авторизован';
          break;
        case 403:
          msg = 'Нет доступа';
          break;
        case 404:
          msg = 'Хаб не найден';
          break;
        case 409:
          msg = 'Конфликт. Возможно, неверный PIN или состояние уже изменено';
          break;
        default:
          final data = (error as dynamic).response?.data;
          final serverMsg =
              (data is Map && data['message'] is String)
                  ? data['message'] as String
                  : null;
          if (serverMsg != null && serverMsg.isNotEmpty) msg = serverMsg;
      }
      _showErrorSnackBar(msg);
    } catch (_) {
      _showErrorSnackBar(fallback);
    }
  }
}
