// lib/features/home/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ISS/services/hub_service.dart';
import 'widgets/device_grid_pro.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';

import 'package:ISS/providers/hubs_provider.dart' as hubsr;
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/services/picovoice_service.dart';
import 'package:ISS/providers/selected_hub_provider.dart';

import 'package:ISS/models/device_models.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/services/weather_service.dart';
import 'package:ISS/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

import 'home_types.dart';
import 'home_controller.dart';
import 'package:ISS/features/devices/device_catalog.dart';
import 'package:ISS/features/devices/device_navigator.dart';

// widgets
import 'package:ISS/features/hub_photo/hub_photo_controller.dart';
import 'widgets/security_status_card.dart';
import 'widgets/overview_grid.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/home_insight_cards.dart';

// sheets
import 'sheets/security_sheet.dart';
import 'sheets/pin_management_sheet.dart';
import 'sheets/set_pins_sheet.dart';
import 'sheets/change_pin_sheet.dart';
import 'sheets/hub_selection_sheet.dart';
import 'sheets/image_picker_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _RoomSummary {
  const _RoomSummary({required this.name, required this.count});
  final String name;
  final int count;
}

class _ClimateSnapshot {
  const _ClimateSnapshot({this.temperature, this.humidity});
  final double? temperature;
  final double? humidity;
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final _RoomSummary summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAll = summary.name == 'Все';
    final baseColor = AppColors.getCardBackgroundColor(context);
    final gradientColors =
        selected
            ? const [Color(0xFF6C63FF), Color(0xFF46A6FF)]
            : [
              baseColor.withValues(alpha: 0.95),
              baseColor.withValues(alpha: 0.78),
            ];

    final textColor =
        selected ? Colors.white : AppColors.getPrimaryTextColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.name,
                style: AppStyles.bodyText2(
                  context,
                ).copyWith(color: textColor, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? Colors.white.withValues(alpha: 0.24)
                          : AppColors.getSecondaryTextColor(
                            context,
                          ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.count.toString(),
                  style: AppStyles.caption(context).copyWith(
                    color:
                        selected
                            ? Colors.white
                            : AppColors.getPrimaryTextColor(
                              context,
                            ).withValues(alpha: isAll ? 0.9 : 0.8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeroSection extends StatelessWidget {
  const _HomeHeroSection({
    required this.hub,
    required this.backgroundUrl,
    required this.micAnimation,
    required this.picovoiceState,
    required this.onChangeHub,
    required this.onToggleMic,
    required this.onUploadPhoto,
    required this.onOpenPins,
    required this.onStartPairing,
    required this.onDetach,
    required this.onRename,
    required this.totalDevices,
    required this.onlineDevices,
    required this.armed,
  });

  final HubObject hub;
  final String? backgroundUrl;
  final Animation<double> micAnimation;
  final PicovoiceState picovoiceState;
  final VoidCallback onChangeHub;
  final VoidCallback onToggleMic;
  final VoidCallback onUploadPhoto;
  final VoidCallback onOpenPins;
  final VoidCallback onStartPairing;
  final VoidCallback onDetach;
  final VoidCallback onRename;
  final int totalDevices;
  final int onlineDevices;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      colors: [Color(0xFF2E4EFF), Color(0xFF5169FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final textColor = Colors.white;
    final secondary = Colors.white.withValues(alpha: 0.7);

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: gradient),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (backgroundUrl != null && backgroundUrl!.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.network(
                    backgroundUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              )
            else
              Positioned(
                right: -60,
                top: -40,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 240),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onChangeHub,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Мой дом',
                            style: AppStyles.caption(
                              context,
                            ).copyWith(color: secondary, letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hub.facilityName.isNotEmpty
                                ? hub.facilityName
                                : 'Без названия',
                            style: AppStyles.headline2(context).copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hub.address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              hub.address,
                              style: AppStyles.caption(
                                context,
                              ).copyWith(color: secondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _HeroCircleButton(
                          onTap: onToggleMic,
                          background: Colors.white.withValues(alpha: 0.18),
                          child: ScaleTransition(
                            scale: micAnimation,
                            child: Icon(
                              picovoiceState == PicovoiceState.stopped
                                  ? Icons.mic_off_outlined
                                  : Icons.mic_none_rounded,
                              color:
                                  picovoiceState ==
                                          PicovoiceState.listeningForCommand
                                      ? AppColors.secondaryAccent
                                      : Colors.white,
                            ),
                          ),
                        ),
                        _HeroCircleButton(
                          onTap: onUploadPhoto,
                          background: Colors.white.withValues(alpha: 0.18),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                          ),
                        ),
                        _HeroMenuButton(
                          onSelected: (value) {
                            switch (value) {
                              case 'pins':
                                onOpenPins();
                                break;
                              case 'pairing':
                                onStartPairing();
                                break;
                              case 'rename':
                                onRename();
                                break;
                              case 'detach':
                                onDetach();
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            armed
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            armed
                                ? 'Система под охраной'
                                : 'Система не активна',
                            style: AppStyles.caption(
                              context,
                            ).copyWith(color: textColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final available = constraints.maxWidth;
                        final double baseWidth =
                            available >= 560
                                ? (available - 32) / 3
                                : (available - 12) / 2;
                        final stats = <Widget>[
                          SizedBox(
                            width: baseWidth,
                            child: _HeroStatTile(
                              label: 'Устройства',
                              value: totalDevices.toString(),
                            ),
                          ),
                          SizedBox(
                            width: baseWidth,
                            child: _HeroStatTile(
                              label: 'Онлайн',
                              value: onlineDevices.toString(),
                            ),
                          ),
                          SizedBox(
                            width: baseWidth,
                            child: _HeroStatTile(
                              label: 'Комнат',
                              value:
                                  hub.rooms.isEmpty
                                      ? '—'
                                      : hub.rooms.length.toString(),
                            ),
                          ),
                        ];
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: stats,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.onTap,
    required this.background,
    required this.child,
  });

  final VoidCallback onTap;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Center(child: child)),
      ),
    );
  }
}

class _HeroMenuButton extends StatelessWidget {
  const _HeroMenuButton({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        color: AppColors.getCardBackgroundColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder:
            (context) => const [
              PopupMenuItem<String>(
                value: 'pins',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.admin_panel_settings_outlined),
                  title: Text('PIN-коды'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'pairing',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.leak_add_outlined),
                  title: Text('Поиск устройств'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'rename',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Переименовать'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'detach',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.link_off, color: AppColors.error),
                  title: Text(
                    'Отвязать хаб',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppStyles.headline3(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppStyles.caption(
              context,
            ).copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
}

class _HomeShortcutStrip extends StatelessWidget {
  const _HomeShortcutStrip({required this.items, this.onTap});

  final List<_ShortcutItem> items;
  final void Function(_ShortcutItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ShortcutTile(item: item, onTap: onTap);
        },
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.item, this.onTap});

  final _ShortcutItem item;
  final void Function(_ShortcutItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = AppColors.getCardBackgroundColor(context);
    final shadowColor = Theme.of(context).shadowColor.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(item),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyText1(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.caption(
                      context,
                    ).copyWith(color: AppColors.getSecondaryTextColor(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_ClimateSnapshot _extractClimateSnapshot(List<DeviceCardVm> cards) {
  for (final vm in cards) {
    if (vm.kind == DeviceUiKind.climate) {
      final temperature = (vm.extra['temperature'] as num?)?.toDouble();
      final humidity = (vm.extra['humidity'] as num?)?.toDouble();
      return _ClimateSnapshot(temperature: temperature, humidity: humidity);
    }
  }
  return const _ClimateSnapshot();
}

bool _isDeviceActiveVm(DeviceCardVm vm) {
  if (vm.disconnected) return false;
  final on = vm.extra['on'];
  if (on is bool) return on;
  final state = vm.extra['state'];
  if (state is String) {
    final normalized = state.toLowerCase();
    if (normalized == 'on' || normalized == 'open') return true;
    if (normalized == 'off' || normalized == 'close') return false;
  }
  final status = vm.extra['status'];
  if (status is String) {
    final normalized = status.toLowerCase();
    if (normalized.contains('alarm') ||
        normalized.contains('open') ||
        normalized.contains('motion') ||
        normalized.contains('leak') ||
        normalized.contains('vibration') ||
        normalized.contains('occupied') ||
        normalized == '1' ||
        normalized == 'true') {
      return true;
    }
  }
  final brightness = vm.extra['brightness'];
  if (brightness is num) return brightness > 0;
  return !vm.disconnected;
}

Map<String, dynamic>? _buildTogglePayload(DeviceCardVm vm, bool nextState) {
  switch (vm.kind) {
    case DeviceUiKind.lightDimmer:
    case DeviceUiKind.relay:
      return {'state': nextState ? 'ON' : 'OFF'};
    case DeviceUiKind.curtain:
      return {'state': nextState ? 'open' : 'close'};
    default:
      return null;
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  HubObject? _selectedHub;
  String _selectedRoom = 'Все';
  bool _isSecurityActionLoading = false;
  final Map<String, bool> _armedOverrideByHubId = {};
  WeatherInfo? _weatherInfo;
  bool _weatherLoading = false;
  String? _weatherHubId;
  bool _locationAttempted = false;
  ProviderSubscription<LocationState>? _locationSub;
  final WeatherService _weatherService = WeatherService();

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  ProviderSubscription<PicovoiceState>? _picovoiceSub;

  // PIN
  final _pinInputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(8),
  ];
  bool _isPinValid(String v) => v.isNotEmpty && v.length >= 4 && v.length <= 8;

  late HomeController _controller;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _controller = HomeController(ref: ref, context: context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.connectInitialHub();
    });

    _picovoiceSub = ref.listenManual<PicovoiceState>(picovoiceProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      if (next == PicovoiceState.listeningForCommand) {
        _animationController.repeat(reverse: true);
      } else {
        if (_animationController.isAnimating) {
          _animationController.stop();
          _animationController.reset();
        }
      }
    }, fireImmediately: true);

    _locationSub = ref.listenManual<LocationState>(
      locationStateProvider,
      (prev, next) {
        final prevPos = prev?.lastPosition;
        final nextPos = next.lastPosition;
        if (_selectedHub == null || nextPos == null) return;
        final changed = prevPos == null ||
            prevPos.latitude != nextPos.latitude ||
            prevPos.longitude != nextPos.longitude;
        if (changed) {
          _fetchWeatherForHub(_selectedHub!);
        }
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _picovoiceSub?.close();
    _animationController.dispose();
    _locationSub?.close();
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

  BaseDevice _mergeLive(BaseDevice d, Map<String, Map<String, dynamic>> map) =>
      _controller.mergeLive(d, map);

  Future<void> _onHubChanged(HubObject hub) async {
    if (!mounted) return;
    setState(() {
      _selectedHub = hub;
      _selectedRoom = 'Все';
    });
    await _controller.onHubChanged(hub);
    if (!mounted) return;
    await _fetchWeatherForHub(hub);
  }

  Future<void> _refreshHubs() async {
    await _controller.refreshHubs(_selectedHub);
    final hub = _selectedHub;
    if (hub != null) {
      await _fetchWeatherForHub(hub);
    }
  }

  Future<void> _pickAndUploadHubPhoto(HubObject hub) async {
    final ImageSource? source = await showImagePickerSheet(context);
    if (!mounted || source == null) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _controller.uploadHubPhoto(hub: hub, file: File(picked.path));
  }

  Future<bool> _toggleDevice({
    required String hubId,
    required DeviceCardVm vm,
    required bool nextState,
  }) async {
    final payload = _buildTogglePayload(vm, nextState);
    if (payload == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Для устройства недоступно переключение'),
          ),
        );
      }
      return false;
    }

    try {
      final commandKey = vm.deviceId.trim();
      if (commandKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось определить устройство')),
          );
        }
        return false;
      }

      final ws = ref.read(webSocketNotifierProvider.notifier);
      ws.updateDeviceLocalState(commandKey, payload);
      await ws.sendDeviceCommand(hubId, commandKey, payload);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить команду: $error')),
        );
      }
      return false;
    }
  }

  Future<void> _fetchWeatherForHub(HubObject hub) async {
    if (!mounted) return;
    setState(() {
      _weatherLoading = true;
      _weatherHubId = hub.commandHubId;
    });

    WeatherInfo? info;
    final locationState = ref.read(locationStateProvider);
    Position? pos = locationState.lastPosition;

    if (pos == null && !_locationAttempted) {
      _locationAttempted = true;
      try {
        await ref
            .read(locationStateProvider.notifier)
            .requestPermissionAndSend();
        pos = ref.read(locationStateProvider).lastPosition;
      } catch (e) {
        debugPrint('[Home] location request error: $e');
      }
    }

    if (pos != null) {
      info = await _weatherService.fetchWeatherByCoordinates(
        pos.latitude,
        pos.longitude,
      );
    }

    if (info == null) {
      final query = hub.address.isNotEmpty
          ? hub.address
          : (hub.space?.name ?? hub.facilityName);
      if (query.trim().isNotEmpty) {
        info = await _weatherService.fetchWeatherByQuery(query);
      }
    }

    if (!mounted) return;
    setState(() {
      _weatherInfo = info;
      _weatherLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final hubsAsyncValue = ref.watch(hubsr.hubsProvider);
    final picovoiceState = ref.watch(picovoiceProvider);
    final hubPhotoState = ref.watch(hubPhotoControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: _buildBackgroundDecoration(context),
        child: SafeArea(
          bottom: false,
          child: hubsAsyncValue.when(
            data: (hubs) {
              if (hubs.isEmpty) return _buildEmptyState(loc);

              if (_selectedHub == null ||
                  !hubs.any(
                    (h) => h.commandHubId == (_selectedHub?.commandHubId ?? ''),
                  )) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && hubs.isNotEmpty) _onHubChanged(hubs.first);
                });
              }

              if (_selectedHub == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final currentHub = hubs.firstWhere(
                (h) => h.commandHubId == _selectedHub!.commandHubId,
                orElse: () => hubs.first,
              );

              final liveState = ref.watch(webSocketNotifierProvider);
              final liveDataMap = liveState.deviceData;

              final updatedDevices =
                  currentHub.devices
                      .map((d) => _mergeLive(d, liveDataMap))
                      .toList();

              final cards = buildDeviceCatalog(
                devices: updatedDevices,
                liveById: liveDataMap,
              );

              final climateSnapshot = _extractClimateSnapshot(cards);
              final activeDevicesCount =
                  cards.where((device) => _isDeviceActiveVm(device)).length;
              final statusIndicators = DeviceUtils.createStatusIndicators(
                updatedDevices,
                loc,
                context,
              );

              final isArmed = _effectiveArmed(
                currentHub.commandHubId,
                currentHub.onMonitoring,
              );

              final roomSummaries = _buildRoomSummaries(cards);
              final effectiveRoom =
                  roomSummaries.any((summary) => summary.name == _selectedRoom)
                      ? _selectedRoom
                      : 'Все';
              final filteredCards =
                  effectiveRoom == 'Все'
                      ? cards
                      : cards.where((device) {
                        final room =
                            device.roomName.trim().isEmpty
                                ? 'Без комнаты'
                                : device.roomName.trim();
                        return room == effectiveRoom;
                      }).toList();
              final onlineDevices =
                  cards.where((device) => !device.disconnected).length;
              final backgroundUrl = hubPhotoState.url;

              return RefreshIndicator(
                onRefresh: _refreshHubs,
                edgeOffset: 48,
                color: AppColors.primaryAccent,
                backgroundColor: AppColors.getCardBackgroundColor(context),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: _HomeHeroSection(
                          hub: currentHub,
                          backgroundUrl: backgroundUrl,
                          micAnimation: _animation,
                          picovoiceState: picovoiceState,
                          onChangeHub: () async {
                            final chosen = await showHubSelectionSheet(
                              context: context,
                              hubs: hubs,
                              selectedHubId:
                                  _selectedHub?.commandHubId ??
                                  ref.read(selectedHubIdProvider),
                            );
                            if (chosen != null) _onHubChanged(chosen);
                          },
                          onToggleMic:
                              () =>
                                  ref
                                      .read(picovoiceProvider.notifier)
                                      .toggleListening(),
                          onUploadPhoto:
                              () => _pickAndUploadHubPhoto(currentHub),
                          onOpenPins: () => _openPinManagementSheet(currentHub),
                          onStartPairing:
                              () => _controller.startPairing(
                                currentHub.commandHubId,
                              ),
                          onDetach: () => _controller.detachHub(currentHub),
                          onRename:
                              () => _showRenameHubDialog(context, currentHub),
                          totalDevices: cards.length,
                          onlineDevices: onlineDevices,
                          armed: isArmed,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          children: [
                            HomeWeatherCard(
                              temperature: _weatherInfo?.temperature ??
                                  climateSnapshot.temperature,
                              humidity: _weatherInfo?.humidity ??
                                  climateSnapshot.humidity,
                              description: _weatherInfo?.description,
                              isLoading: _weatherLoading &&
                                  _weatherHubId == currentHub.commandHubId,
                              location:
                                  (_weatherInfo?.locationName ??
                                          currentHub.address)
                                      .trim()
                                      .isNotEmpty
                                      ? (_weatherInfo?.locationName ??
                                          currentHub.address)
                                      : currentHub.facilityName,
                            ),
                            const SizedBox(height: 16),
                            HomeEnergyCard(
                              totalDevices: cards.length,
                              activeDevices: activeDevicesCount,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: SecurityStatusCard(
                          isArmed: isArmed,
                          isLoading: _isSecurityActionLoading,
                          onPressed: () => _openSecuritySheet(currentHub),
                        ),
                      ),
                    ),
                    if (statusIndicators.isNotEmpty) ...[
                      _buildSectionHeader(context, loc.homeOverview),
                      OverviewGrid(indicators: statusIndicators),
                    ],
                    _buildSectionHeader(context, loc.quickActions),
                    QuickActionsCard(
                      commandHubId: currentHub.commandHubId,
                      devices: updatedDevices,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: _HomeShortcutStrip(
                          items: const [
                            _ShortcutItem(
                              title: 'Карта',
                              subtitle: 'Зоны, камеры, маршруты',
                              icon: Icons.map_outlined,
                              route: '/home/map',
                            ),
                            _ShortcutItem(
                              title: 'Доступ семьи',
                              subtitle: 'Роли и приглашения',
                              icon: Icons.people_alt_outlined,
                              route: '/family/access',
                            ),
                            _ShortcutItem(
                              title: 'Энергомонитор',
                              subtitle: 'Статистика потребления',
                              icon: Icons.bolt_outlined,
                            ),
                          ],
                          onTap: (item) {
                            if (item.route != null) {
                              context.push(item.route!);
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.title} в разработке'),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (roomSummaries.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Комнаты',
                                style: AppStyles.headline3(context),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 52,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: roomSummaries.length,
                                  separatorBuilder:
                                      (context, _) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final summary = roomSummaries[index];
                                    return _RoomChip(
                                      summary: summary,
                                      selected: summary.name == effectiveRoom,
                                      onTap: () {
                                        setState(() {
                                          _selectedRoom = summary.name;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _buildSectionHeader(context, 'Устройства'),
                    if (filteredCards.isNotEmpty)
                      DeviceGridPro(
                        cards: filteredCards,
                        onTap: (vm) => openDeviceDetails(context, vm),
                        onToggle:
                            (vm, next) => _toggleDevice(
                              hubId: currentHub.commandHubId,
                              vm: vm,
                              nextState: next,
                            ),
                      )
                    else
                      _buildEmptyTileSliver(
                        context,
                        effectiveRoom == 'Все'
                            ? 'Пока нет устройств'
                            : 'В этой комнате пока нет устройств',
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ошибка: $err',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText1(context),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers ----------
  SliverPadding _buildSectionHeader(BuildContext context, String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              width: 8,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF46A6FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppStyles.headline3(context).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.getPrimaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors:
            isDark
                ? const [Color(0xFF0D1117), Color(0xFF161B22)]
                : const [Color(0xFFF5F7FE), Color(0xFFDCE6FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  List<_RoomSummary> _buildRoomSummaries(List<DeviceCardVm> cards) {
    if (cards.isEmpty) {
      return const [_RoomSummary(name: 'Все', count: 0)];
    }

    final Map<String, int> byRoom = {};
    for (final card in cards) {
      final key =
          card.roomName.trim().isEmpty ? 'Без комнаты' : card.roomName.trim();
      byRoom[key] = (byRoom[key] ?? 0) + 1;
    }

    final summaries =
        byRoom.entries
            .map((e) => _RoomSummary(name: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return [_RoomSummary(name: 'Все', count: cards.length), ...summaries];
  }

  Widget _buildEmptyState(AppLocalizations loc) {
    return RefreshIndicator(
      onRefresh: _refreshHubs,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.hub_outlined,
            size: 64,
            color: AppColors.getSecondaryTextColor(context),
          ),
          const SizedBox(height: 16),
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

  SliverPadding _buildEmptyTileSliver(BuildContext context, String text) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      sliver: SliverToBoxAdapter(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppStyles.glassmorphicBoxDecoration(
              context,
            ).copyWith(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.getSecondaryTextColor(context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(text, style: AppStyles.bodyText2(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSecuritySheet(HubObject hub) {
    final isArmed = _effectiveArmed(hub.commandHubId, hub.onMonitoring);
    final pinController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => buildSecuritySheet(
            context: context,
            isArmed: isArmed,
            isLoading: _isSecurityActionLoading,
            pinController: pinController,
            pinFormatters: _pinInputFormatters,
            isPinValid: _isPinValid,
            onArm:
                () => _controller.armSecurity(
                  hub,
                  onStart: () {
                    setState(() {
                      _isSecurityActionLoading = true;
                      _setArmedOverride(hub.commandHubId, true);
                    });
                  },
                  onFinally:
                      () => setState(() => _isSecurityActionLoading = false),
                  clearOverride:
                      () => _setArmedOverride(hub.commandHubId, null),
                  setOverrideOnError:
                      () => _setArmedOverride(hub.commandHubId, false),
                ),
            onDisarm:
                (pin) => _controller.disarmSecurity(
                  hub,
                  pin: pin,
                  onStart: () {
                    setState(() {
                      _isSecurityActionLoading = true;
                      _setArmedOverride(hub.commandHubId, false);
                    });
                  },
                  onFinally:
                      () => setState(() => _isSecurityActionLoading = false),
                  clearOverride:
                      () => _setArmedOverride(hub.commandHubId, null),
                  setOverrideOnError:
                      () => _setArmedOverride(hub.commandHubId, true),
                ),
            onOpenPinManagement: () => _openPinManagementSheet(hub),
          ),
    );
  }

  void _openPinManagementSheet(HubObject hub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => buildPinManagementSheet(
            context: context,
            onSetPins: () {
              Navigator.pop(context);
              _openSetPinsSheet(hub);
            },
            onChangeDisarm: () {
              Navigator.pop(context);
              _openChangePinSheet(hub, type: PinType.disarm);
            },
            onChangeDuress: () {
              Navigator.pop(context);
              _openChangePinSheet(hub, type: PinType.duress);
            },
          ),
    );
  }

  void _openSetPinsSheet(HubObject hub) {
    final disarmCtrl = TextEditingController();
    final duressCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => buildSetPinsSheet(
            context: context,
            disarmCtrl: disarmCtrl,
            duressCtrl: duressCtrl,
            pinFormatters: _pinInputFormatters,
            isPinValid: _isPinValid,
            onSave:
                (disarm, duress) => _controller.setPins(
                  hub,
                  disarmPin: disarm,
                  duressPin: duress,
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
      backgroundColor: Colors.transparent,
      builder:
          (_) => buildChangePinSheet(
            context: context,
            title: title,
            oldCtrl: oldCtrl,
            newCtrl: newCtrl,
            pinFormatters: _pinInputFormatters,
            isPinValid: _isPinValid,
            onSave: (oldPin, newPin) {
              if (type == PinType.disarm) {
                _controller.changeDisarmPin(
                  hub,
                  oldPin: oldPin,
                  newPin: newPin,
                );
              } else {
                _controller.changeDuressPin(
                  hub,
                  oldPin: oldPin,
                  newPin: newPin,
                );
              }
            },
          ),
    );
  }

  void _showRenameHubDialog(BuildContext context, HubObject hub) {
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
              AppLocalizations.of(context).renameHubTitle,
              style: AppStyles.headline4(context),
            ),
            content: TextField(
              controller: c,
              decoration: AppStyles.inputDecoration(
                context: context,
                hintText: 'Новое имя',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                style: AppStyles.primaryButtonStyle,
                onPressed: () async {
                  if (c.text.isEmpty) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final locDialog = AppLocalizations.of(context);
                  final navigator = Navigator.of(dCtx);
                  final success = await ref
                      .read(hubServiceProvider)
                      .renameHub(hub.commandHubId, c.text.trim());
                  if (!mounted) return;
                  navigator.pop();
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(locDialog.hubRenamedSuccess),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    await _refreshHubs();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(locDialog.hubRenamedFailed),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
    );
  }
}
