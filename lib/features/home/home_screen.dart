import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/core/network/dio_provider.dart';

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
import 'package:ISS/features/family/group_list_screen.dart';
import 'package:ISS/features/family/group_manage_screen.dart';
import 'package:ISS/providers/hubs_provider.dart' as hubsr;
import 'package:ISS/providers/family_group_providers.dart' as fg;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(webSocketNotifierProvider.notifier).connect();
    });
  }

  // ==== helpers ====

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
  ) => liveMap[device.id] ?? liveMap[device.friendlyName];

  BaseDevice _mergeLive(
    BaseDevice device,
    Map<String, Map<String, dynamic>> liveMap,
  ) {
    final live = _findLiveFor(device, liveMap);
    if (live == null) return device;
    return DeviceParser.parse({...device.rawData, ...live});
  }

  void _onHubChanged(HubObject newHub) {
    if (!mounted) return;
    setState(() => _selectedHub = newHub);
    ref.read(selectedHubIdProvider.notifier).state = newHub.commandHubId;

    final ws = ref.read(webSocketNotifierProvider.notifier);
    final sent = <String>{};
    for (final d in newHub.devices) {
      if (d.id.isNotEmpty && sent.add(d.id)) {
        ws.sendShareDeviceData(newHub.commandHubId, d.id);
      }
      final fn = d.friendlyName.trim();
      if (fn.isNotEmpty && sent.add(fn)) {
        ws.sendShareDeviceData(newHub.commandHubId, fn);
      }
    }
  }

  Future<void> _refreshHubsEverywhere() async {
    final gid = ref.read(fg.activeFamilyGroupIdProvider);
    await Future.wait([
      ref.refresh(hubsr.hubsProvider.future),
      ref.refresh(hubsr.homeHubsProvider.future),
      if (gid != null) ref.refresh(fg.familyHubsProvider(gid).future),
    ]);
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
      await _refreshHubsEverywhere();
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
      await _refreshHubsEverywhere();
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
      await _refreshHubsEverywhere();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showErrorSnackBar(loc.hubDetachedFailed, e);
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
                    await _refreshHubsEverywhere();
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

    final groupId = ref.watch(fg.activeFamilyGroupIdProvider);
    final role = ref.watch(fg.activeFamilyRoleProvider) ?? fg.FamilyRole.user;
    final allowUserDisarm = ref.watch(fg.allowUserDisarmProvider);
    final isFamilyMode = groupId != null;

    // источники хабов
    final AsyncValue<List<HubObject>> hubsAsyncValue =
        isFamilyMode
            ? ref
                .watch(fg.familyHubsProvider(groupId!))
                .whenData(
                  (list) =>
                      list
                          .map(
                            (e) =>
                                HubObject.fromJson(e as Map<String, dynamic>),
                          )
                          .toList(),
                )
            : ref.watch(hubsr.homeHubsProvider);
    // права
    final canControl = fg.FamilyPermissions.canControlDevices(role);
    final canArm = fg.FamilyPermissions.canArm(role);
    final canDisarm = fg.FamilyPermissions.canDisarm(
      role,
      allowUser: allowUserDisarm,
    );
    final canPins = fg.FamilyPermissions.canManagePins(role);
    final canDetach =
        !isFamilyMode || fg.FamilyPermissions.canAttachDetachHubs(role);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: hubsAsyncValue.when(
        data: (hubs) {
          // EMPTY STATE
          if (hubs.isEmpty) {
            return RefreshIndicator(
              onRefresh:
                  () =>
                      isFamilyMode
                          ? ref.refresh(fg.familyHubsProvider(groupId!).future)
                          : ref.refresh(hubsr.homeHubsProvider.future),
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
                    'Вы можете подключить хаб или настроить семейный доступ.',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyText2(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // Переход в список/создание семейных групп
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GroupListScreen(),
                              ),
                            );
                            ref.invalidate(fg.familyGroupsProvider);
                            await _refreshHubsEverywhere();
                          },
                          icon: const Icon(Icons.groups),
                          label: const Text('Семейный доступ'),
                        ),
                      ),
                      // Если хочешь кнопку подключения Wi-Fi хаба — раскомментируй и добавь роут /wifi-setup
                      // const SizedBox(width: 12),
                      // Expanded(
                      //   child: ElevatedButton.icon(
                      //     onPressed: () => context.push('/wifi-setup'),
                      //     icon: const Icon(Icons.settings_input_antenna),
                      //     label: const Text('Подключить хаб'),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            );
          }

          // ensure selected
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
          final controllableDevices =
              canControl
                  ? DeviceUtils.getControllableDevices(updatedDevices)
                  : <BaseDevice>[];

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

          return RefreshIndicator(
            onRefresh:
                () =>
                    isFamilyMode
                        ? ref.refresh(fg.familyHubsProvider(groupId!).future)
                        : ref.refresh(hubsr.homeHubsProvider.future),
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
                    if (canPins)
                      IconButton(
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                        tooltip: 'PIN-коды',
                        onPressed: () => _openPinManagementSheet(currentHub),
                      ),
                    if (canDetach)
                      IconButton(
                        icon: const Icon(Icons.link_off),
                        tooltip: loc.detachHub,
                        onPressed:
                            () => _showDetachConfirmationDialog(
                              context,
                              currentHub,
                            ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.groups),
                      tooltip:
                          isFamilyMode
                              ? 'Семейный доступ (вкл.)'
                              : 'Семейный доступ',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupListScreen(),
                          ),
                        );
                        ref.invalidate(fg.familyGroupsProvider);
                        await _refreshHubsEverywhere();
                      },
                    ),
                    if (isFamilyMode)
                      IconButton(
                        icon: const Icon(Icons.manage_accounts),
                        tooltip: 'Управление группой',
                        onPressed: () async {
                          final gid = groupId;
                          if (gid == null) return;

                          // найдём имя группы
                          String groupName = 'Группа';
                          try {
                            final groups = await ref.read(
                              fg.familyGroupsProvider.future,
                            );
                            final g = groups
                                .cast<Map<String, dynamic>>()
                                .firstWhere(
                                  (e) => e['id'] == gid,
                                  orElse: () => const {'name': 'Группа'},
                                );
                            if (g['name'] is String &&
                                (g['name'] as String).isNotEmpty) {
                              groupName = g['name'] as String;
                            }
                          } catch (_) {}

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => GroupManageScreen(
                                    groupId: gid,
                                    name: groupName,
                                  ),
                            ),
                          );
                        },
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
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
                        Row(
                          children: [
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
                                    isFamilyMode
                                        ? 'Семейный режим • ${role.name.toUpperCase()}'
                                        : loc.status,
                                    style: AppStyles.caption(context).copyWith(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        if (canArm || (isArmed && canDisarm))
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSecurityActionLoading
                                      ? null
                                      : () {
                                        if (isArmed) {
                                          if (!canDisarm) return;
                                          _openSecuritySheet(currentHub);
                                        } else {
                                          if (!canArm) return;
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
                          )
                        else
                          const SizedBox.shrink(),
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
                if (canControl) ...[
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
                ],

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
