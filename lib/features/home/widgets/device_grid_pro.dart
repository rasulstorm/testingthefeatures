// lib/features/home/widgets/device_grid_pro.dart
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/devices/device_catalog.dart';

class _DeviceMetric {
  const _DeviceMetric({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class DeviceGridPro extends StatelessWidget {
  const DeviceGridPro({
    super.key,
    required this.cards,
    required this.onTap,
    this.onToggle,
  });

  final List<DeviceCardVm> cards;
  final void Function(DeviceCardVm vm) onTap;
  final Future<bool> Function(DeviceCardVm vm, bool nextState)? onToggle;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isVeryNarrow = screenW < 360;
    final isNarrow = screenW < 420;

    // Наращиваем высоту тайлов на небольших экранах, чтобы текст точно помещался
    final aspect = isVeryNarrow ? 0.56 : (isNarrow ? 0.60 : 0.66);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final vm = cards[i];
          final toggleSupported = _supportsDeviceToggle(vm) && onToggle != null;
          return _DeviceTile(
            vm: vm,
            onTap: () => onTap(vm),
            onToggle: toggleSupported ? (next) => onToggle!(vm, next) : null,
            initialActive: _isDeviceActive(vm),
          );
        }, childCount: cards.length),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 20,
          childAspectRatio: aspect,
        ),
      ),
    );
  }
}

class _DeviceTile extends StatefulWidget {
  const _DeviceTile({
    required this.vm,
    required this.onTap,
    required this.initialActive,
    this.onToggle,
  });

  final DeviceCardVm vm;
  final VoidCallback onTap;
  final bool initialActive;
  final Future<bool> Function(bool nextState)? onToggle;

  @override
  State<_DeviceTile> createState() => _DeviceTileState();
}

class _DeviceTileState extends State<_DeviceTile> {
  late bool _isActive;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.initialActive;
  }

  @override
  void didUpdateWidget(covariant _DeviceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vm.deviceId != widget.vm.deviceId ||
        oldWidget.initialActive != widget.initialActive) {
      _isActive = widget.initialActive;
    }
  }

  Future<void> _handleToggle() async {
    if (widget.onToggle == null || _busy) return;
    final next = !_isActive;
    setState(() {
      _busy = true;
      _isActive = next;
    });
    final ok = await widget.onToggle!(next);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _isActive = !next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final roomLabel = vm.roomName.isNotEmpty ? vm.roomName : 'Без комнаты';
    final accentColor =
        _isActive ? const Color(0xFFFFB84D) : const Color(0xFF7C7F88);
    final background =
        _isActive
            ? const Color(0xFF111217)
            : AppColors.getCardBackgroundColor(context);
    final iconBackground =
        _isActive ? const Color(0xFF26293A) : const Color(0xFFE7E8EC);
    final status = _presentStatus(vm, _isActive);
    final Color baseTextColor =
        _isActive ? Colors.white : AppColors.getPrimaryTextColor(context);
    final Color statusColor =
        status.isAlert
            ? const Color(0xFFFF8A80)
            : (_isActive
                ? Colors.white
                : AppColors.getPrimaryTextColor(context));
    final bool showToggle = widget.onToggle != null;

    final metrics = _buildMetrics(vm);

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isActive ? 0.2 : 0.05),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final compact = h < 220;
            final ultraCompact = h < 200;

            final double pad = ultraCompact ? 11 : (compact ? 12 : 14);
            final vGapSmall = compact ? 6.0 : 12.0;
            final vGapTiny = compact ? 3.0 : 10.0;

            final titleSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.headline3(context).copyWith(
                    color: baseTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: ultraCompact ? 16 : (compact ? 17 : 18),
                  ),
                ),
                if (!ultraCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    roomLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.caption(context).copyWith(
                      color:
                          _isActive
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            );

            final statusDetails = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status.primary,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyText1(context).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13.5 : 14,
                  ),
                ),
                if (!compact && status.secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    status.secondary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.caption(context).copyWith(
                      color:
                          _isActive
                              ? Colors.white.withValues(alpha: 0.65)
                              : AppColors.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ],
            );

            Widget trailing;
            if (showToggle) {
              trailing = GestureDetector(
                onTap: _handleToggle,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: compact ? 44 : 48,
                  height: compact ? 24 : 28,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color:
                        _isActive
                            ? const Color(0xFF26293A)
                            : AppColors.getSecondaryTextColor(
                              context,
                            ).withValues(alpha: 0.18),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    alignment:
                        _isActive
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      width: compact ? 16 : 20,
                      height: compact ? 16 : 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          _busy
                              ? const Padding(
                                padding: EdgeInsets.all(3),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
              );
            } else {
              trailing = Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.getSecondaryTextColor(
                  context,
                ).withValues(alpha: 0.6),
                size: compact ? 14 : 16,
              );
            }

            final bool stackTrailing = constraints.maxWidth < 200;

            final statusBlock = stackTrailing
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      statusDetails,
                      SizedBox(height: vGapTiny),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: trailing,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: statusDetails),
                      const SizedBox(width: 10),
                      FittedBox(fit: BoxFit.scaleDown, child: trailing),
                    ],
                  );

            final bool showMetrics = metrics.isNotEmpty && !compact;

            final metricsWrap = !showMetrics
                ? null
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metrics
                        .map(
                          (m) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(m.icon, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  m.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: compact ? 44 : 48,
                        height: compact ? 44 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBackground,
                        ),
                        child: vm.asset.isNotEmpty
                            ? Padding(
                                padding: EdgeInsets.all(compact ? 6 : 7),
                                child: Image.asset(
                                  vm.asset,
                                  color: _isActive ? accentColor : null,
                                  colorBlendMode: _isActive
                                      ? BlendMode.srcIn
                                      : BlendMode.srcOver,
                                ),
                              )
                            : Icon(
                                Icons.widgets_rounded,
                                color: accentColor,
                                size: compact ? 22 : 26,
                              ),
                      ),
                      const Spacer(),
                      if (vm.disconnected)
                        Flexible(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _SignalPill(
                                lq: null,
                                disconnected: true,
                              ),
                            ),
                          ),
                        )
                      else if (vm.linkquality != null)
                        Flexible(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _SignalPill(
                                lq: vm.linkquality,
                                disconnected: false,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: vGapSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleSection,
                        SizedBox(height: vGapSmall),
                        statusBlock,
                        if (metricsWrap != null) ...[
                          SizedBox(height: vGapSmall),
                          metricsWrap,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<_DeviceMetric> _buildMetrics(DeviceCardVm vm) {
  final extra = vm.extra;
  final metrics = <_DeviceMetric>[];

  num? _num(dynamic v) => v is num ? v : null;
  String _formatPercent(num value) => '${value.round()}%';
  String _formatTemp(num value) => '${value.toStringAsFixed(1)}°C';
  String _formatHum(num value) => '${value.round()}% RH';
  String _formatLux(num value) => '${value.round()} лк';
  String _formatPower(num value) =>
      value >= 10 ? '${value.round()} Вт' : '${value.toStringAsFixed(1)} Вт';

  final battery = _num(extra['battery']);
  if (battery != null) {
    metrics.add(
      _DeviceMetric(
        icon: Icons.battery_charging_full_rounded,
        label: _formatPercent(battery),
      ),
    );
  }

  switch (vm.kind) {
    case DeviceUiKind.climate:
      final t = _num(extra['temperature']);
      final h = _num(extra['humidity']);
      if (t != null) {
        metrics.add(
          _DeviceMetric(icon: Icons.thermostat, label: _formatTemp(t)),
        );
      }
      if (h != null) {
        metrics.add(
          _DeviceMetric(icon: Icons.water_drop, label: _formatHum(h)),
        );
      }
      final lx = _num(extra['illuminance']);
      if (lx != null) {
        metrics.add(
          _DeviceMetric(icon: Icons.wb_sunny_outlined, label: _formatLux(lx)),
        );
      }
      break;

    case DeviceUiKind.curtain:
      final pos = _num(extra['position']);
      if (pos != null) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.swap_vert_rounded,
            label: 'Открыто ${pos.round()}%',
          ),
        );
      }
      final motor = extra['motor_state']?.toString();
      if (motor != null && motor.isNotEmpty) {
        metrics.add(
          _DeviceMetric(icon: Icons.engineering_rounded, label: motor),
        );
      }
      break;

    case DeviceUiKind.relay:
      final power = _num(extra['power']);
      if (power != null) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.flash_on_rounded,
            label: _formatPower(power),
          ),
        );
      }
      final voltage = _num(extra['voltage']);
      if (voltage != null) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.bolt_rounded,
            label: '${voltage.round()} В',
          ),
        );
      }
      break;

    case DeviceUiKind.sensorMotion:
      final occupied = extra['occupied'];
      if (occupied is bool) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.sensors,
            label: occupied ? 'Движение' : 'Тихо',
          ),
        );
      }
      final lx = _num(extra['illuminance']);
      if (lx != null) {
        metrics.add(
          _DeviceMetric(icon: Icons.wb_sunny_outlined, label: _formatLux(lx)),
        );
      }
      break;

    case DeviceUiKind.sensorContact:
      final contact = extra['contact'];
      if (contact is bool) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.sensor_door_rounded,
            label: contact ? 'Закрыто' : 'Открыто',
          ),
        );
      }
      break;

    case DeviceUiKind.sensorLeak:
      final leak = extra['water_leak'];
      if (leak is bool) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.water_damage_outlined,
            label: leak ? 'Протечка' : 'Сухо',
          ),
        );
      }
      break;

    case DeviceUiKind.sensorVibration:
      final vib = extra['vibration'];
      if (vib is bool) {
        metrics.add(
          _DeviceMetric(
            icon: Icons.vibration,
            label: vib ? 'Вибрация' : 'Спокойно',
          ),
        );
      }
      break;

    case DeviceUiKind.lightDimmer:
      final brightness = _num(extra['brightness']);
      if (brightness != null) {
        final percent = (brightness / 255 * 100).clamp(0, 100);
        metrics.add(
          _DeviceMetric(
            icon: Icons.lightbulb_outline,
            label: _formatPercent(percent),
          ),
        );
      }
      break;

    case DeviceUiKind.unknown:
      final state = extra['state']?.toString();
      if (state != null && state.isNotEmpty) {
        metrics.add(_DeviceMetric(icon: Icons.info_outline, label: state));
      }
      break;
  }

  return metrics;
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.primary,
    this.secondary,
    this.isAlert = false,
  });
  final String primary;
  final String? secondary;
  final bool isAlert;
}

_StatusPresentation _presentStatus(DeviceCardVm vm, bool isActive) {
  final extras = vm.extra;
  final statusRaw = (extras['status'] as String?)?.toLowerCase();
  final battery = (extras['battery'] as num?)?.toDouble();
  final batteryText =
      battery != null ? 'Батарея ${battery.toStringAsFixed(0)}%' : null;

  switch (vm.kind) {
    case DeviceUiKind.lightDimmer:
      final brightness = (extras['brightness'] as num?)?.toDouble();
      final colorTemp = (extras['color_temp'] as num?)?.toDouble();
      final power = (extras['power'] as num?)?.toDouble();
      final brightnessText =
          brightness != null
              ? 'Яркость ${(brightness / 255 * 100).clamp(0, 100).round()}%'
              : null;
      final colorText = colorTemp != null ? '${colorTemp.round()}K' : null;
      final powerText =
          power != null
              ? '${power.toStringAsFixed(power >= 10 ? 0 : 1)} Вт'
              : null;
      return _StatusPresentation(
        primary: isActive ? 'Включено' : 'Выключено',
        secondary: _joinSecondary([
          brightnessText,
          colorText,
          powerText,
          batteryText,
        ]),
      );
    case DeviceUiKind.relay:
      final power = (extras['power'] as num?)?.toDouble();
      final voltage = (extras['voltage'] as num?)?.toDouble();
      final current = (extras['current'] as num?)?.toDouble();
      return _StatusPresentation(
        primary: isActive ? 'Включено' : 'Выключено',
        secondary: _joinSecondary([
          power != null
              ? '${power.toStringAsFixed(power >= 10 ? 0 : 1)} Вт'
              : null,
          voltage != null ? '${voltage.round()} В' : null,
          current != null
              ? '${current.toStringAsFixed(current >= 10 ? 0 : 1)} А'
              : null,
          batteryText,
        ]),
      );
    case DeviceUiKind.curtain:
      final position = (extras['position'] as num?)?.toDouble();
      final state = (extras['state'] as String?)?.toLowerCase();
      final motorState = (extras['motor_state'] as String?)?.toLowerCase();
      String primary;
      if (position != null) {
        primary = 'Открыто на ${position.round()}%';
      } else if (state != null) {
        primary = state == 'open' ? 'Открыто' : 'Закрыто';
      } else {
        primary = isActive ? 'Открыто' : 'Закрыто';
      }
      final motorLabel =
          motorState != null && motorState.isNotEmpty && motorState != 'stopped'
              ? motorState
              : null;
      return _StatusPresentation(
        primary: primary,
        secondary: _joinSecondary([motorLabel, batteryText]),
      );
    case DeviceUiKind.climate:
      final temperature = (extras['temperature'] as num?)?.toDouble();
      final humidity = (extras['humidity'] as num?)?.toDouble();
      final pressure = (extras['pressure'] as num?)?.toDouble();
      final deviceTemp = (extras['device_temperature'] as num?)?.toDouble();
      final tempText =
          temperature != null
              ? '${temperature.toStringAsFixed(1)}°C'
              : 'Нет данных';
      final humidityText =
          humidity != null ? 'Влажность ${humidity.toStringAsFixed(0)}%' : null;
      return _StatusPresentation(
        primary: tempText,
        secondary: _joinSecondary([
          humidityText,
          pressure != null ? '${pressure.toStringAsFixed(0)} гПа' : null,
          deviceTemp != null
              ? 'Датчик ${deviceTemp.toStringAsFixed(0)}°C'
              : null,
          batteryText,
        ]),
      );
    case DeviceUiKind.sensorMotion:
      final occupied = extras['occupied'] as bool?;
      final presence = extras['presence'] as bool?;
      bool triggered = occupied ?? presence ?? false;
      if (!triggered) {
        triggered = _matches(statusRaw, [
          'motion',
          'occupied',
          'alarm',
          '1',
          'active',
        ]);
      }
      final illuminance = (extras['illuminance'] as num?)?.toDouble();
      return _StatusPresentation(
        primary: triggered ? 'Движение' : 'Тихо',
        secondary: _joinSecondary([
          illuminance != null ? '${illuminance.round()} лк' : null,
          batteryText,
        ]),
        isAlert: triggered,
      );
    case DeviceUiKind.sensorContact:
      final contact = extras['contact'] as bool?;
      bool opened;
      if (contact != null) {
        opened = !contact;
      } else {
        opened = _matches(statusRaw, ['open', 'opened', '1', 'true']);
      }
      final tamper = extras['tamper'] as bool?;
      return _StatusPresentation(
        primary: opened ? 'Открыто' : 'Закрыто',
        secondary: _joinSecondary([
          tamper == true ? 'Тревога корпуса' : null,
          batteryText,
        ]),
        isAlert: opened,
      );
    case DeviceUiKind.sensorLeak:
      final leakFlag = extras['water_leak'] as bool?;
      bool leak = leakFlag ?? false;
      if (leakFlag == null)
        leak = _matches(statusRaw, ['leak', 'alarm', 'on', 'true', 'detected']);
      return _StatusPresentation(
        primary: leak ? 'Протечка!' : 'Сухо',
        secondary: batteryText,
        isAlert: leak,
      );
    case DeviceUiKind.sensorVibration:
      final vibFlag = extras['vibration'] as bool?;
      bool vib = vibFlag ?? false;
      if (vibFlag == null)
        vib = _matches(statusRaw, ['vibration', 'tilt', 'drop', 'alarm']);
      final action = extras['action'] as String?;
      return _StatusPresentation(
        primary: vib ? 'Вибрация' : 'Спокойно',
        secondary: _joinSecondary([action, batteryText]),
        isAlert: vib,
      );
    case DeviceUiKind.unknown:
      return _StatusPresentation(
        primary: isActive ? 'Активно' : 'Не активно',
        secondary: batteryText,
      );
  }
}

String? _joinSecondary(List<String?> values) {
  final filtered =
      values.whereType<String>().where((v) => v.trim().isNotEmpty).toList();
  if (filtered.isEmpty) return null;
  return filtered.join(' · ');
}

bool _matches(String? value, List<String> positives) {
  if (value == null) return false;
  final normalized = value.trim().toLowerCase();
  for (final candidate in positives) {
    if (normalized.contains(candidate)) return true;
  }
  return false;
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({this.lq, required this.disconnected});
  final int? lq;
  final bool disconnected;

  @override
  Widget build(BuildContext context) {
    Color c;
    String t;
    if (disconnected || lq == null) {
      c = Colors.grey;
      t = 'нет связи';
    } else if (lq! < 60) {
      c = Colors.redAccent;
      t = 'низкий';
    } else if (lq! < 110) {
      c = Colors.orangeAccent;
      t = 'средний';
    } else {
      c = Colors.green;
      t = 'хороший';
    }
    final pillBg = Colors.white.withValues(alpha: 0.24);
    final border = Colors.white.withValues(alpha: 0.4);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              t,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _supportsDeviceToggle(DeviceCardVm vm) {
  switch (vm.kind) {
    case DeviceUiKind.lightDimmer:
    case DeviceUiKind.relay:
    case DeviceUiKind.curtain:
      return true;
    default:
      return false;
  }
}

bool _isDeviceActive(DeviceCardVm vm) {
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
    if (_matches(normalized, [
      'alarm',
      'open',
      'motion',
      'leak',
      'vibration',
      'occupied',
      '1',
      'true',
    ])) {
      return true;
    }
  }
  final brightness = vm.extra['brightness'];
  if (brightness is num) return brightness > 0;
  return !vm.disconnected;
}
