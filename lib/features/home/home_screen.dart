// lib/features/home/home_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/core/network/dio_provider.dart';

import 'package:ISS/features/voice/voice_mic_button.dart';
import 'package:ISS/features/security_control/ws_provider.dart';

import 'package:ISS/widgets/status_indicator_card.dart';
import 'package:ISS/widgets/quick_action_button.dart';
import 'package:ISS/widgets/control_device_card.dart';

import 'package:ISS/models/device_models.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/utils/device_parser.dart';
import 'package:ISS/utils/device_utils.dart';

import 'package:ISS/providers/selected_hub_provider.dart';
import 'package:ISS/services/hub_service.dart';
import 'package:ISS/providers/hubs_provider.dart' as hubsr;

// Фото хаба
import 'package:ISS/features/hub_photo/hub_photo_controller.dart';

enum PinType { disarm, duress }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HubObject? _selectedHub;
  bool _isSecurityActionLoading = false;
  final Map<String, bool> _armedOverrideByHubId = {};

  @override
  void initState() {
    super.initState();
    // Если hubId уже сохранён — подключаемся сразу.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final savedHubId = ref.read(selectedHubIdProvider);
      if (savedHubId != null && savedHubId.isNotEmpty) {
        ref.read(webSocketNotifierProvider.notifier).connect(savedHubId);
      }
    });
  }

  @override
  void dispose() {
    ref.read(webSocketNotifierProvider.notifier).disconnect();
    super.dispose();
  }

  bool _effectiveArmed(String hubId, bool backendValue) =>
      _armedOverrideByHubId[hubId] ?? backendValue;

  void _setArmedOverride(String hubId, bool? value) {
    if (!mounted) return;
    setState(() {
      if (value == null) {
        _armedOverrideByHubId.remove(hubId);
      } else {
        _armedOverrideByHubId[hubId] = value;
      }
    });
  }

  Map<String, dynamic>? _findLiveFor(
    BaseDevice device,
    Map<String, Map<String, dynamic>> liveMap,
  ) {
    final byId = liveMap[device.id];
    if (byId != null) return byId;
    final fn = (device.friendlyName ?? '').trim();
    if (fn.isEmpty) return null;
    return liveMap[fn];
  }

  BaseDevice _mergeLive(
    BaseDevice device,
    Map<String, Map<String, dynamic>> liveMap,
  ) {
    final live = _findLiveFor(device, liveMap);
    if (live == null) return device;
    return DeviceParser.parse({...device.rawData, ...live});
  }

  void _shareHubDevicesOverWs(HubObject hub) {
    final ws = ref.read(webSocketNotifierProvider.notifier);
    final sent = <String>{};
    for (final d in hub.devices) {
      if (d.id.isNotEmpty && sent.add(d.id)) {
        ws.sendShareDeviceData(hub.commandHubId, d.id);
      }
      final fn = (d.friendlyName ?? '').trim();
      if (fn.isNotEmpty && sent.add(fn)) {
        ws.sendShareDeviceData(hub.commandHubId, fn);
      }
    }
  }

  void _onHubChanged(HubObject newHub) {
    if (!mounted) return;
    setState(() => _selectedHub = newHub);

    // Сохраняем выбранный hubId (commandHubId) как и раньше:
    ref.read(selectedHubIdProvider.notifier).state = newHub.commandHubId;

    // Пере-подключаем WS под нужный hubId:
    final ws = ref.read(webSocketNotifierProvider.notifier);
    ws.disconnect();
    ws.connect(newHub.commandHubId);

    // Отправляем SHARE подписки
    _shareHubDevicesOverWs(newHub);

    // Загружаем фото по UUID (hub.id)
    ref.read(hubPhotoControllerProvider.notifier).loadForHub(newHub.id);
  }

  Future<void> _refreshHubs() async {
    await ref.refresh(hubsr.hubsProvider.future);
    final hub = _selectedHub;
    if (hub != null) {
      await ref.read(hubPhotoControllerProvider.notifier).loadForHub(hub.id);
    }
  }

  Future<void> _armSecurity(HubObject hub) async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isSecurityActionLoading = true;
      _setArmedOverride(hub.commandHubId, true);
    });
    try {
      await dio.post('/hub/${hub.commandHubId}/arm-security');
      _showSuccessSnackBar(loc.securityArmed);
      await _refreshHubs();
      _setArmedOverride(hub.commandHubId, null);
    } catch (e) {
      _setArmedOverride(hub.commandHubId, false);
      _handleApiError(e, fallback: 'Не удалось поставить на охрану');
    } finally {
      if (mounted) setState(() => _isSecurityActionLoading = false);
    }
  }

  Future<void> _disarmSecurity(HubObject hub, String pin) async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isSecurityActionLoading = true;
      _setArmedOverride(hub.commandHubId, false);
    });
    try {
      await dio.post(
        '/hub/${hub.commandHubId}/disarm-security',
        data: {'pin': pin},
      );
      _showSuccessSnackBar(loc.securityDisarmed);
      await _refreshHubs();
      _setArmedOverride(hub.commandHubId, null);
    } catch (e) {
      _setArmedOverride(hub.commandHubId, true);
      _handleApiError(e, fallback: 'Не удалось снять с охраны');
    } finally {
      if (mounted) setState(() => _isSecurityActionLoading = false);
    }
  }

  Future<void> _setPins(
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

  Future<void> _changeDisarmPin(
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

  Future<void> _changeDuressPin(
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

  Future<void> _startPairing(String hubId) async {
    final loc = AppLocalizations.of(context);
    final service = ref.read(hubServiceProvider);
    final ok = await service.startPairing(hubId);
    if (!mounted) return;
    ok
        ? _showSuccessSnackBar(loc.pairingStartedSuccess)
        : _showErrorSnackBar(loc.pairingStartedFailed);
  }

  Future<void> _detachHub(HubObject hub) async {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await dio.post('/mobile/hub/${hub.id}/detach');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessSnackBar(loc.hubDetachedSuccess);
      await _refreshHubs();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar(loc.hubDetachedFailed, e);
    }
  }

  // ==== photo upload ====

  Future<void> _pickAndUploadHubPhoto(HubObject hub) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getSecondaryTextColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Камера'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Галерея'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );

    if (!mounted || source == null) return;

    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);

      final ok = await ref
          .read(hubPhotoControllerProvider.notifier)
          .uploadForHub(
            hubUuid: hub.id, // здесь hub.id (UUID)
            file: file,
            type: 'ROOM',
            name: 'Главная обложка',
          );
      if (ok) {
        _showSuccessSnackBar('Фото обновлено');
      } else {
        _showErrorSnackBar('Не удалось загрузить фото');
      }
    } on PlatformException catch (e) {
      _showErrorSnackBar('Нет разрешения на камеру/файлы: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Ошибка выбора фото: $e');
    }
  }

  // ==== UI helpers ====

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

  void _showErrorSnackBar(String message, [dynamic error]) {
    if (!mounted) return;
    final text = '$message${error != null ? ' : $error' : ''}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  void _showRenameHubDialog(BuildContext context, HubObject hub) {
    final loc = AppLocalizations.of(context);
    final c = TextEditingController(text: hub.facilityName);
    showDialog(
      context: context,
      builder:
          (dCtx) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusAll(16),
            ),
            title: Text(
              loc.renameHubTitle,
              style: AppStyles.headline4(context),
            ),
            content: TextField(controller: c),
            actions: [
              const VoiceMicButton(),
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: Text(loc.cancel),
              ),
              ElevatedButton(
                style: AppStyles.primaryButtonStyle,
                onPressed: () async {
                  if (c.text.isEmpty) return;
                  final service = ref.read(hubServiceProvider);
                  final success = await service.renameHub(
                    hub.commandHubId,
                    c.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.pop(dCtx);
                  if (success) {
                    _showSuccessSnackBar(loc.hubRenamedSuccess);
                    await _refreshHubs();
                  } else {
                    _showErrorSnackBar(loc.hubRenamedFailed);
                  }
                },
                child: const Text(
                  'Сохранить',
                  style: TextStyle(color: AppColors.textColorDark),
                ),
              ),
            ],
          ),
    );
  }

  void _showDetachConfirmationDialog(BuildContext context, HubObject hub) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (dCtx) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusAll(16),
            ),
            title: Text(
              loc.detachHubTitle,
              style: AppStyles.headline4(context),
            ),
            content: Text(loc.detachHubConfirmation(hub.facilityName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: Text(loc.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dCtx);
                  _detachHub(hub);
                },
                child: const Text(
                  'Открепить',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ==== PIN sheets ====

  final _pinInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
  ];
  bool _isPinValid(String v) => v.isNotEmpty && v.length >= 4 && v.length <= 8;

  void _openSecuritySheet(HubObject hub) {
    final loc = AppLocalizations.of(context);
    final isArmed = _effectiveArmed(hub.commandHubId, hub.onMonitoring);
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: MediaQuery.of(
              context,
            ).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetGrabber(context),
                Text(
                  isArmed ? loc.disarm : loc.arm,
                  style: AppStyles.headline3(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  isArmed
                      ? 'Введите PIN для снятия с охраны'
                      : 'Постановка на охрану не требует PIN.',
                  style: AppStyles.bodyText2(context),
                ),
                const SizedBox(height: 16),
                if (isArmed)
                  TextField(
                    controller: pinController,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: _pinInputFormatters,
                    decoration: const InputDecoration(
                      labelText: 'PIN (4–8 цифр)',
                      filled: true,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: AppStyles.primaryButtonStyle.copyWith(
                      minimumSize: WidgetStateProperty.all(
                        const Size(double.infinity, 50),
                      ),
                    ),
                    onPressed:
                        _isSecurityActionLoading
                            ? null
                            : () {
                              if (isArmed) {
                                final pin = pinController.text.trim();
                                if (!_isPinValid(pin)) {
                                  _showErrorSnackBar(
                                    'Некорректный PIN (4–8 цифр)',
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _disarmSecurity(hub, pin);
                              } else {
                                Navigator.pop(context);
                                _armSecurity(hub);
                              }
                            },
                    icon:
                        _isSecurityActionLoading
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textColorDark,
                              ),
                            )
                            : Icon(
                              isArmed
                                  ? Icons.lock_open_rounded
                                  : Icons.security_rounded,
                              color: AppColors.textColorDark,
                            ),
                    label: Text(
                      isArmed ? loc.disarm : loc.arm,
                      style: const TextStyle(color: AppColors.textColorDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openPinManagementSheet(hub);
                  },
                  child: const Text('Управление PIN-кодами'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  void _openPinManagementSheet(HubObject hub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetGrabber(context),
                  Row(
                    children: [
                      Text(
                        'PIN-коды охраны',
                        style: AppStyles.headline3(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PinActionTile(
                    icon: Icons.key_rounded,
                    title: 'Назначить PIN-коды',
                    subtitle: 'Основной и тревожный',
                    onTap: () {
                      Navigator.pop(context);
                      _openSetPinsSheet(hub);
                    },
                  ),
                  const SizedBox(height: 8),
                  _PinActionTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Сменить основной PIN',
                    subtitle: 'Изменить disarm PIN',
                    onTap: () {
                      Navigator.pop(context);
                      _openChangePinSheet(hub, type: PinType.disarm);
                    },
                  ),
                  const SizedBox(height: 8),
                  _PinActionTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Сменить тревожный PIN',
                    subtitle: 'Изменить duress PIN',
                    onTap: () {
                      Navigator.pop(context);
                      _openChangePinSheet(hub, type: PinType.duress);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _openSetPinsSheet(HubObject hub) {
    final disarmCtrl = TextEditingController();
    final duressCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: MediaQuery.of(
              context,
            ).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetGrabber(context),
                _sheetTitle(context, 'Назначить PIN-коды'),
                const SizedBox(height: 12),
                TextField(
                  controller: disarmCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: _pinInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Основной PIN (disarm)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: duressCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: _pinInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Тревожный PIN (duress)',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppStyles.primaryButtonStyle,
                    onPressed: () {
                      final disarm = disarmCtrl.text.trim();
                      final duress = duressCtrl.text.trim();
                      if (!_isPinValid(disarm) || !_isPinValid(duress)) {
                        _showErrorSnackBar('PIN должен быть 4–8 цифр');
                        return;
                      }
                      Navigator.pop(context);
                      _setPins(hub, disarmPin: disarm, duressPin: duress);
                    },
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(color: AppColors.textColorDark),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  void _openChangePinSheet(HubObject hub, {required PinType type}) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final title =
        type == PinType.disarm
            ? 'Сменить основной PIN'
            : 'Сменить тревожный PIN';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: MediaQuery.of(
              context,
            ).viewInsets.add(const EdgeInsets.all(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetGrabber(context),
                _sheetTitle(context, title),
                const SizedBox(height: 12),
                TextField(
                  controller: oldCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: _pinInputFormatters,
                  decoration: const InputDecoration(labelText: 'Старый PIN'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: _pinInputFormatters,
                  decoration: const InputDecoration(
                    labelText: 'Новый PIN (4–8 цифр)',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppStyles.primaryButtonStyle,
                    onPressed: () {
                      final oldPin = oldCtrl.text.trim();
                      final newPin = newCtrl.text.trim();
                      if (!_isPinValid(oldPin) || !_isPinValid(newPin)) {
                        _showErrorSnackBar('PIN должен быть 4–8 цифр');
                        return;
                      }
                      Navigator.pop(context);
                      if (type == PinType.disarm) {
                        _changeDisarmPin(hub, oldPin: oldPin, newPin: newPin);
                      } else {
                        _changeDuressPin(hub, oldPin: oldPin, newPin: newPin);
                      }
                    },
                    child: const Text(
                      'Сохранить',
                      style: TextStyle(color: AppColors.textColorDark),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  Widget _sheetGrabber(BuildContext context) => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: AppColors.getSecondaryTextColor(context),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _sheetTitle(BuildContext context, String title) => Text(
    title,
    style: AppStyles.headline3(context).copyWith(fontWeight: FontWeight.bold),
  );

  // ==== build ====

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final webSocketState = ref.watch(webSocketNotifierProvider);
    final webSocketConnected = webSocketState.isConnected;

    final AsyncValue<List<HubObject>> hubsAsyncValue = ref.watch(
      hubsr.hubsProvider,
    );

    final hubPhotoState = ref.watch(hubPhotoControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: hubsAsyncValue.when(
        data: (hubs) {
          if (hubs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshHubs,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  Icon(
                    Icons.hub_outlined,
                    size: 64,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.noHubsFound,
                    textAlign: TextAlign.center,
                    style: AppStyles.headline3(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Подключите ваш хаб, чтобы управлять устройствами.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyText2(context),
                  ),
                ],
              ),
            );
          }

          if (_selectedHub == null ||
              !hubs.any((h) => h.commandHubId == _selectedHub!.commandHubId)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _onHubChanged(hubs.first);
            });
          }
          if (_selectedHub == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final HubObject currentHub = hubs.firstWhere(
            (h) => h.commandHubId == _selectedHub!.commandHubId,
            orElse: () => hubs.first,
          );

          final liveDataMap = webSocketState.deviceData;
          final updatedDevices =
              currentHub.devices
                  .map((d) => _mergeLive(d, liveDataMap))
                  .toList();

          final statusIndicators = DeviceUtils.createStatusIndicators(
            updatedDevices,
            loc,
            context,
          );

          final controllableDevices = DeviceUtils.getControllableDevices(
            updatedDevices,
          );

          final isArmed = _effectiveArmed(
            currentHub.commandHubId,
            currentHub.onMonitoring,
          );

          final buttonText = isArmed ? loc.disarm : loc.arm;
          final buttonIcon =
              isArmed ? Icons.lock_open_rounded : Icons.security_rounded;
          final buttonBg =
              isArmed
                  ? AppColors.getCardBackgroundColor(context)
                  : AppColors.primaryAccent;
          final buttonFg =
              isArmed ? AppColors.primaryAccent : AppColors.textColorDark;

          final backgroundUrl = hubPhotoState.url; // уже с cache-bust

          return RefreshIndicator(
            onRefresh: _refreshHubs,
            color: AppColors.primaryAccent,
            backgroundColor: AppColors.getCardBackgroundColor(context),
            child: CustomScrollView(
              slivers: [
                // ======= HEADER =======
                SliverAppBar(
                  expandedHeight: 220,
                  floating: false,
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Обложка дома',
                      onPressed: () => _pickAndUploadHubPhoto(currentHub),
                    ),
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      tooltip: 'PIN-коды',
                      onPressed: () => _openPinManagementSheet(currentHub),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_off),
                      tooltip: loc.detachHub,
                      onPressed:
                          () => _showDetachConfirmationDialog(
                            context,
                            currentHub,
                          ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (backgroundUrl != null)
                          Image.network(
                            backgroundUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: AppColors.getBackgroundColor(context),
                                ),
                          )
                        else
                          Image.asset(
                            'assets/images/home_background.jpg',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: AppColors.getBackgroundColor(context),
                                ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.35),
                              ],
                            ),
                          ),
                        ),
                        if (hubPhotoState.loading)
                          Container(
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                    titlePadding: const EdgeInsets.only(
                      left: 16,
                      bottom: 10,
                      right: 16,
                    ),
                    centerTitle: false,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap:
                              () => _showRenameHubDialog(context, currentHub),
                          borderRadius: AppStyles.borderRadiusAll(8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  currentHub.facilityName,
                                  style: AppStyles.headline3(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                webSocketConnected
                                    ? Icons.wifi
                                    : Icons.wifi_off,
                                size: 14,
                                color:
                                    webSocketConnected
                                        ? Colors.lightGreenAccent
                                        : Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                loc.status,
                                style: AppStyles.caption(
                                  context,
                                ).copyWith(fontSize: 11, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ======= TOP ACTIONS =======
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSecurityActionLoading
                                    ? null
                                    : () {
                                      if (isArmed) {
                                        _openSecuritySheet(currentHub);
                                      } else {
                                        _armSecurity(currentHub);
                                      }
                                    },
                            icon:
                                _isSecurityActionLoading
                                    ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: buttonFg,
                                      ),
                                    )
                                    : Icon(buttonIcon, color: buttonFg),
                            label: Text(
                              buttonText,
                              style: AppStyles.bodyText1(
                                context,
                              ).copyWith(color: buttonFg),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBg,
                              disabledBackgroundColor: buttonBg.withOpacity(
                                0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppStyles.borderRadiusAll(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildIconButton(
                          context,
                          icon: Icons.leak_add_outlined,
                          tooltip: loc.startPairing,
                          onPressed:
                              () => _startPairing(currentHub.commandHubId),
                        ),
                        const SizedBox(width: 12),
                        _buildIconButton(
                          context,
                          icon: Icons.list_alt,
                          tooltip: loc.selectHub,
                          onPressed:
                              () => _showHubSelectionBottomSheet(context, hubs),
                        ),
                      ],
                    ),
                  ),
                ),

                // ======= OVERVIEW =======
                if (statusIndicators.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        loc.homeOverview,
                        style: AppStyles.headline3(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: statusIndicators.length,
                      itemBuilder:
                          (_, i) => CompactStatusIndicatorCard(
                            indicator: statusIndicators[i],
                          ),
                    ),
                  ),
                ] else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _emptyTile(context, loc.noDataAvailable),
                    ),
                  ),
                ],

                // ======= QUICK ACTIONS =======
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      loc.quickActions,
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: QuickActionButton(
                            label: loc.switchAll,
                            icon: Icons.power,
                            onTap: () {
                              final controllable =
                                  DeviceUtils.getControllableDevices(
                                    updatedDevices,
                                  );
                              final ws = ref.read(
                                webSocketNotifierProvider.notifier,
                              );
                              final sent = <String>{};
                              for (final d in controllable) {
                                if (sent.add(d.id)) {
                                  ws.sendDeviceCommand(
                                    currentHub.commandHubId,
                                    d.id,
                                    {"state": "ON"},
                                  );
                                  ws.updateDeviceLocalState(d.id, {
                                    'state': 'ON',
                                  });
                                }
                              }
                              _showSuccessSnackBar(loc.switchAllSuccess);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: QuickActionButton(
                            label: loc.powerOffAll,
                            icon: Icons.power_off,
                            onTap: () {
                              final controllable =
                                  DeviceUtils.getControllableDevices(
                                    updatedDevices,
                                  );
                              final ws = ref.read(
                                webSocketNotifierProvider.notifier,
                              );
                              final sent = <String>{};
                              for (final d in controllable) {
                                if (sent.add(d.id)) {
                                  ws.sendDeviceCommand(
                                    currentHub.commandHubId,
                                    d.id,
                                    {"state": "OFF"},
                                  );
                                  ws.updateDeviceLocalState(d.id, {
                                    'state': 'OFF',
                                  });
                                }
                              }
                              _showSuccessSnackBar(loc.powerOffAllSuccess);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ======= DEVICES =======
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      loc.controllableDevices,
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (controllableDevices.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: controllableDevices.length,
                      itemBuilder:
                          (_, i) => ControlDeviceCard(
                            device: controllableDevices[i],
                            commandHubId: currentHub.commandHubId,
                          ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverToBoxAdapter(
                      child: _emptyTile(context, loc.noControllableDevices),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
        loading:
            () => Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            ),
        error:
            (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${loc.errorLoadingData}: $err',
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: AppColors.error),
                ),
              ),
            ),
      ),
    );
  }

  // ==== small widgets ====

  Widget _emptyTile(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration(context).copyWith(
        borderRadius: AppStyles.borderRadiusAll(12),
        color: AppColors.getCardBackgroundColor(context),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.getSecondaryTextColor(context),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppStyles.bodyText2(context))),
        ],
      ),
    );
  }

  void _showHubSelectionBottomSheet(
    BuildContext context,
    List<HubObject> hubs,
  ) {
    final loc = AppLocalizations.of(context);
    final selectedId = ref.read(selectedHubIdProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      loc.selectHub,
                      style: AppStyles.headline4(context),
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: hubs.length,
                      separatorBuilder:
                          (_, __) => Divider(
                            color: AppColors.getBorderGrayColor(context),
                            height: 1,
                          ),
                      itemBuilder: (_, i) {
                        final hub = hubs[i];
                        final isSelected =
                            hub.commandHubId ==
                            (selectedId ?? _selectedHub?.commandHubId);
                        return ListTile(
                          tileColor: AppColors.getCardBackgroundColor(context),
                          title: Text(
                            hub.facilityName,
                            style: AppStyles.bodyText1(context).copyWith(
                              color:
                                  isSelected
                                      ? AppColors.primaryAccent
                                      : AppColors.getTextColor(context),
                            ),
                          ),
                          subtitle: Text(
                            hub.commandHubId,
                            style: AppStyles.caption(context),
                          ),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryAccent,
                                  )
                                  : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppStyles.borderRadiusAll(12),
                          ),
                          onTap: () {
                            _onHubChanged(hub);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: AppStyles.cardDecoration(context).copyWith(
        borderRadius: AppStyles.borderRadiusAll(12),
        color: AppColors.getCardBackgroundColor(context),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.getTextColor(context)),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _PinActionTile extends StatelessWidget {
  const _PinActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppStyles.borderRadiusAll(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppStyles.cardDecoration(context).copyWith(
          borderRadius: AppStyles.borderRadiusAll(12),
          color: AppColors.getCardBackgroundColor(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyText1(
                      context,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppStyles.bodyText2(context)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
