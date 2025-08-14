// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/widgets/status_indicator_card.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/providers/selected_hub_provider.dart';
import 'package:ISS/services/hub_service.dart';
import 'package:ISS/utils/device_parser.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/widgets/quick_action_button.dart';
import 'package:ISS/widgets/control_device_card.dart';

enum PinType { disarm, duress }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HubObject? _selectedHub;

  // блокируем кнопки на время сетевых действий
  bool _isSecurityActionLoading = false;

  // локальный оверрайд состояния охраны (мгновенный UX)
  final Map<String, bool> _armedOverrideByHubId = {};

  // ===== lifecycle =====
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(webSocketNotifierProvider.notifier).connect();
    });
  }

  // ===== helpers: override =====
  bool _effectiveArmed(String hubId, bool backendValue) {
    return _armedOverrideByHubId.containsKey(hubId)
        ? _armedOverrideByHubId[hubId]!
        : backendValue;
  }

  void _setArmedOverride(String hubId, bool? value) {
    setState(() {
      if (value == null) {
        _armedOverrideByHubId.remove(hubId);
      } else {
        _armedOverrideByHubId[hubId] = value;
      }
    });
  }

  // ===== hub select / ws share =====
  void _onHubChanged(HubObject newHub) {
    if (!mounted) return;
    setState(() => _selectedHub = newHub);
    ref.read(selectedHubIdProvider.notifier).state = newHub.commandHubId;

    for (var device in newHub.devices) {
      ref
          .read(webSocketNotifierProvider.notifier)
          .sendShareDeviceData(newHub.commandHubId, device.friendlyName);
    }
  }

  // =========================
  // SECURITY API (по ТЗ)
  // =========================

  /// Постановка на охрану (ARM)
  /// POST /api/v1/hub/{id}/arm-security  (без тела)
  Future<void> _armSecurity(HubObject hub) async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isSecurityActionLoading = true;
      _setArmedOverride(hub.commandHubId, true); // оптимистично
    });

    try {
      await dio.post('/hub/${hub.commandHubId}/arm-security');
      _showSuccessSnackBar(loc.securityArmed);
      // обновим данные от бэка
      await ref.refresh(hubsProvider.future);
      _setArmedOverride(hub.commandHubId, null);
    } on Object catch (e) {
      // откат
      _setArmedOverride(hub.commandHubId, false);
      _handleApiError(e, fallback: 'Не удалось поставить на охрану');
    } finally {
      if (mounted) setState(() => _isSecurityActionLoading = false);
    }
  }

  /// Снятие с охраны (DISARM)
  /// POST /api/v1/hub/{id}/disarm-security  { "pin": "1234" }
  Future<void> _disarmSecurity(HubObject hub, String pin) async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isSecurityActionLoading = true;
      _setArmedOverride(hub.commandHubId, false); // оптимистично
    });

    try {
      await dio.post(
        '/hub/${hub.commandHubId}/disarm-security',
        data: {'pin': pin},
      );
      _showSuccessSnackBar(loc.securityDisarmed);
      await ref.refresh(hubsProvider.future);
      _setArmedOverride(hub.commandHubId, null);
    } on Object catch (e) {
      // откат
      _setArmedOverride(hub.commandHubId, true);
      _handleApiError(e, fallback: 'Не удалось снять с охраны');
    } finally {
      if (mounted) setState(() => _isSecurityActionLoading = false);
    }
  }

  /// Назначение PIN-кодов
  /// POST /api/v1/hub/{id}/set-pins
  /// { "disarmPin": "...", "duressPin": "..." }
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
    } on Object catch (e) {
      _handleApiError(e, fallback: 'Не удалось сохранить PIN-коды');
    }
  }

  /// Обновление основного PIN
  /// PUT /api/v1/hub/{id}/new-disarm-pin
  /// { "oldPin": "...", "newPin": "..." }
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
    } on Object catch (e) {
      _handleApiError(e, fallback: 'Не удалось изменить PIN');
    }
  }

  /// Обновление тревожного PIN
  /// PUT /api/v1/hub/{id}/new-duress-pin
  /// { "oldPin": "...", "newPin": "..." }
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
    } on Object catch (e) {
      _handleApiError(e, fallback: 'Не удалось изменить тревожный PIN');
    }
  }

  // ======================
  // Ошибки / Snackbar
  // ======================

  void _handleApiError(Object error, {required String fallback}) {
    // Можно распарсить DioException и коды
    try {
      // ignore: avoid_dynamic_calls
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
          // если есть сообщение с бэка
          final data = (error as dynamic).response?.data;
          final serverMsg =
              (data is Map && data['message'] is String)
                  ? data['message'] as String
                  : null;
          if (serverMsg != null && serverMsg.isNotEmpty) {
            msg = serverMsg;
          }
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

  // ======================
  // Разное: detach/rename/pairing
  // ======================

  void _showRenameHubDialog(BuildContext context, HubObject hub) {
    final localizations = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: hub.facilityName);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadiusAll(16),
          ),
          title: Text(
            localizations.renameHubTitle,
            style: AppStyles.headline4(context),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: AppStyles.bodyText1(context),
            cursorColor: AppColors.primaryAccent,
            decoration: InputDecoration(
              hintText: localizations.enterNewNameHint,
              hintStyle: AppStyles.bodyText2(context),
              filled: false,
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.getBorderGrayColor(context),
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.getBorderGrayColor(context),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryAccent,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: AppStyles.primaryButtonStyle.copyWith(
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(color: AppColors.textColorDark),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final service = ref.read(hubServiceProvider);
                final success = await service.renameHub(
                  hub.commandHubId,
                  nameController.text,
                );
                if (!mounted) return;
                Navigator.pop(dialogContext);
                if (success) {
                  _showSuccessSnackBar(localizations.hubRenamedSuccess);
                  ref.refresh(hubsProvider.future);
                } else {
                  _showErrorSnackBar(localizations.hubRenamedFailed);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _detachHub(HubObject hub) async {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await dio.post('/mobile/hub/${hub.id}/detach');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSuccessSnackBar(localizations.hubDetachedSuccess);
      ref.invalidate(hubsProvider);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar(localizations.hubDetachedFailed, e);
    }
  }

  void _showDetachConfirmationDialog(BuildContext context, HubObject hub) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadiusAll(16),
          ),
          title: Text(
            localizations.detachHubTitle,
            style: AppStyles.headline4(context),
          ),
          content: Text(
            localizations.detachHubConfirmation(hub.facilityName),
            style: AppStyles.bodyText1(context),
          ),
          actions: [
            TextButton(
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text(
                'Открепить',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _detachHub(hub);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _startPairing(String hubId) async {
    final localizations = AppLocalizations.of(context)!;
    final service = ref.read(hubServiceProvider);
    final success = await service.startPairing(hubId);
    if (!mounted) return;
    if (success) {
      _showSuccessSnackBar(localizations.pairingStartedSuccess);
    } else {
      _showErrorSnackBar(localizations.pairingStartedFailed);
    }
  }

  // ======================
  // PIN bottom sheets
  // ======================

  final _pinInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
  ];
  bool _isPinValid(String v) => v.isNotEmpty && v.length >= 4 && v.length <= 8;

  void _openSecuritySheet(HubObject hub) {
    final loc = AppLocalizations.of(context)!;
    final isArmed = _effectiveArmed(hub.commandHubId, hub.onMonitoring);
    final title = isArmed ? loc.disarm : loc.arm;
    final pinController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(
            context,
          ).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetGrabber(context),
              Text(
                title,
                style: AppStyles.headline3(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                isArmed
                    ? 'Введите PIN для снятия с охраны'
                    : 'Постановка на охрану не требует PIN (по ТЗ).',
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
                  style: AppStyles.primaryButtonStyle.copyWith(
                    minimumSize: MaterialStateProperty.all(
                      const Size(double.infinity, 50),
                    ),
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
        );
      },
    );
  }

  void _openPinManagementSheet(HubObject hub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
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
                  subtitle: 'Основной (disarm) и тревожный (duress)',
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
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
      builder: (_) {
        return Padding(
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
        );
      },
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
      builder: (_) {
        return Padding(
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
        );
      },
    );
  }

  // ===== sheet UI helpers =====
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

  // ======================
  // BUILD
  // ======================

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hubsAsyncValue = ref.watch(hubsProvider);
    final webSocketState = ref.watch(webSocketNotifierProvider);
    final webSocketConnected = webSocketState.isConnected;

    final activeGroupId = ref.watch(activeFamilyGroupIdProvider);
    final bool isFamilyMode = activeGroupId != null;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: hubsAsyncValue.when(
        data: (hubs) {
          if (hubs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(hubsProvider.future),
              child: Stack(
                children: [ListView(), Center(child: Text(loc.noHubsFound))],
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

          // live merge
          final liveDataMap = webSocketState.deviceData;
          final List<BaseDevice> updatedDevices =
              currentHub.devices.map((device) {
                final liveData = liveDataMap[device.friendlyName];
                if (liveData != null) {
                  final mergedData = {...device.rawData, ...liveData};
                  return DeviceParser.parse(mergedData);
                }
                return device;
              }).toList();

          final List<StatusIndicator> realStatusIndicators =
              DeviceUtils.createStatusIndicators(updatedDevices, loc, context);
          final List<BaseDevice> controllableDevices =
              DeviceUtils.getControllableDevices(updatedDevices);

          final bool isArmed = _effectiveArmed(
            currentHub.commandHubId,
            currentHub.onMonitoring,
          );
          final String buttonText = isArmed ? loc.disarm : loc.arm;
          final IconData buttonIcon =
              isArmed ? Icons.lock_open_rounded : Icons.security_rounded;
          final Color buttonBackgroundColor =
              isArmed
                  ? AppColors.getCardBackgroundColor(context)
                  : AppColors.primaryAccent;
          final Color buttonTextColor =
              isArmed ? AppColors.primaryAccent : AppColors.textColorDark;

          return RefreshIndicator(
            onRefresh: () => ref.refresh(hubsProvider.future),
            color: AppColors.primaryAccent,
            backgroundColor: AppColors.getCardBackgroundColor(context),
            child: CustomScrollView(
              slivers: [
                if (isFamilyMode)
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      tooltip: 'PIN-коды',
                      onPressed: () => _openPinManagementSheet(currentHub),
                    ),
                    if (!isFamilyMode)
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
                    background: Image.asset(
                      'assets/images/home_background.jpg',
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: AppColors.getBackgroundColor(context),
                            child: Center(
                              child: Text(
                                '${loc.errorLoadingImage}\nassets/images/home_background.jpg',
                                textAlign: TextAlign.center,
                                style: AppStyles.bodyText2(
                                  context,
                                ).copyWith(color: AppColors.error),
                              ),
                            ),
                          ),
                    ),
                    titlePadding: EdgeInsets.zero,
                    centerTitle: false,
                    title: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      color: AppColors.getBackgroundColor(
                        context,
                      ).withOpacity(0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap:
                                () => _showRenameHubDialog(context, currentHub),
                            borderRadius: AppStyles.borderRadiusAll(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 2.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      currentHub.facilityName,
                                      style: AppStyles.headline3(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.getSecondaryTextColor(
                                      context,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                loc.status,
                                style: AppStyles.caption(
                                  context,
                                ).copyWith(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Tooltip(
                                message:
                                    webSocketConnected
                                        ? loc.online
                                        : loc.offline,
                                child: Icon(
                                  webSocketConnected
                                      ? Icons.wifi
                                      : Icons.wifi_off,
                                  color:
                                      webSocketConnected
                                          ? Colors.green
                                          : Colors.redAccent,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSecurityActionLoading
                                      ? null
                                      : () => _openSecuritySheet(currentHub),
                              icon:
                                  _isSecurityActionLoading
                                      ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: buttonTextColor,
                                        ),
                                      )
                                      : Icon(
                                        buttonIcon,
                                        color: buttonTextColor,
                                      ),
                              label: Text(
                                buttonText,
                                style: AppStyles.bodyText1(
                                  context,
                                ).copyWith(color: buttonTextColor),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonBackgroundColor,
                                disabledBackgroundColor: buttonBackgroundColor
                                    .withOpacity(0.5),
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
                            icon: Icons.list,
                            tooltip: loc.list,
                            onPressed:
                                () =>
                                    _showHubSelectionBottomSheet(context, hubs),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      loc.homeOverview,
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (realStatusIndicators.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: realStatusIndicators.length,
                      itemBuilder:
                          (context, index) => CompactStatusIndicatorCard(
                            indicator: realStatusIndicators[index],
                          ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          loc.noDataAvailable,
                          style: AppStyles.bodyText2(context),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      loc.quickActions,
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                              for (var device in controllable) {
                                ref
                                    .read(webSocketNotifierProvider.notifier)
                                    .sendDeviceCommand(
                                      currentHub.commandHubId,
                                      device.friendlyName,
                                      {"state": "ON"},
                                    );
                                ref
                                    .read(webSocketNotifierProvider.notifier)
                                    .updateDeviceLocalState(
                                      device.friendlyName,
                                      {'state': 'ON'},
                                    );
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
                              for (var device in controllable) {
                                ref
                                    .read(webSocketNotifierProvider.notifier)
                                    .sendDeviceCommand(
                                      currentHub.commandHubId,
                                      device.friendlyName,
                                      {"state": "OFF"},
                                    );
                                ref
                                    .read(webSocketNotifierProvider.notifier)
                                    .updateDeviceLocalState(
                                      device.friendlyName,
                                      {'state': 'OFF'},
                                    );
                              }
                              _showSuccessSnackBar(loc.powerOffAllSuccess);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      loc.controllableDevices,
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (controllableDevices.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 1.0,
                          ),
                      itemCount: controllableDevices.length,
                      itemBuilder:
                          (context, index) => ControlDeviceCard(
                            device: controllableDevices[index],
                            commandHubId: currentHub.commandHubId,
                          ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          loc.noControllableDevices,
                          style: AppStyles.bodyText2(context),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
        loading:
            () => Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            ),
        error:
            (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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

  // ============== misc UI ==============
  void _showHubSelectionBottomSheet(
    BuildContext context,
    List<HubObject> hubs,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final selectedId = ref.read(selectedHubIdProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getCardBackgroundColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  localizations.selectHub,
                  style: AppStyles.headline4(context),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: hubs.length,
                  itemBuilder: (context, index) {
                    final hub = hubs[index];
                    final bool isSelected =
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
                      selected: isSelected,
                      selectedTileColor: AppColors.primaryAccent.withOpacity(
                        0.1,
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
        );
      },
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
