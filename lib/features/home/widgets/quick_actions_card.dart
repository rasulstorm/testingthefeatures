import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'round_toggle_button.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/l10n/app_localizations.dart';

import '../utils/device_keys.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/utils/device_utils.dart';

/// Компактная карточка "Быстрые действия".
/// ВАЖНО: внутренний заголовок убран — заголовок рисует HomeScreen через _buildSectionHeader().
class QuickActionsCard extends ConsumerStatefulWidget {
  final String commandHubId;
  final List<BaseDevice> devices;

  const QuickActionsCard({
    super.key,
    required this.commandHubId,
    required this.devices,
  });

  @override
  ConsumerState<QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<QuickActionsCard> {
  bool _busy = false;
  bool _allOn = false;

  @override
  void didUpdateWidget(covariant QuickActionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.devices != widget.devices && !_busy) {
      _allOn = _computeAggregateOn(widget.devices);
    }
  }

  bool _computeAggregateOn(List<BaseDevice> devices) {
    final controllable = DeviceUtils.getControllableDevices(devices);
    for (final d in controllable) {
      try {
        final dyn = d as dynamic;
        final Map<String, dynamic>? st = dyn.state as Map<String, dynamic>?;
        final raw =
            (st?['state'] ?? st?['power'] ?? st?['on'] ?? '').toString();
        if (raw.toUpperCase() == 'ON' || raw == 'true') return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> _toggleAll(bool next) async {
    if (_busy) return false;
    setState(() => _busy = true);

    final controllable = DeviceUtils.getControllableDevices(widget.devices);
    final ws = ref.read(webSocketNotifierProvider.notifier);
    final stateStr = next ? 'ON' : 'OFF';

    try {
      for (final d in controllable) {
        final key = DeviceKeys.commandKey(d);
        debugPrint(
          '[QuickActions] command hub=${widget.commandHubId} deviceName=$key payload={state: $stateStr}',
        );
        ws.updateDeviceLocalState(key, {'state': stateStr}); // мгновенный UI
        await ws.sendDeviceCommand(widget.commandHubId, key, {
          'state': stateStr,
        });
      }
      if (mounted) setState(() => _allOn = next);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // динамический лейбл для одной кнопки
    final label = _allOn ? loc.powerOffAll : loc.switchAll;
    final controllableCount =
        DeviceUtils.getControllableDevices(widget.devices).length;

    final theme = Theme.of(context);
    final toggleTheme = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.white,
        onPrimary: AppColors.primaryAccent,
        surfaceContainerHighest: Colors.white.withValues(alpha: 0.18),
        onSurface: Colors.white,
      ),
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF232C61), Color(0xFF2F3E90)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF232C61).withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppStyles.headline4(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Одним касанием управляйте всеми подключенными устройствами.',
                      style: AppStyles.bodyText2(
                        context,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    if (controllableCount > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Доступно устройств: $controllableCount',
                          style: AppStyles.caption(
                            context,
                          ).copyWith(color: Colors.white, letterSpacing: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Theme(
                data: toggleTheme,
                child: RoundToggleButton(
                  label: '',
                  isOn: _allOn,
                  loading: _busy,
                  iconOn: Icons.power_settings_new_rounded,
                  iconOff: Icons.power_settings_new_outlined,
                  size: 72,
                  onToggle: _toggleAll,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
