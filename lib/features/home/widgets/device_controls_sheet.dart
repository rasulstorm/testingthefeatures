import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/features/home/utils/device_keys.dart';
import 'device_theme.dart';

Future<void> showDeviceControlsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required BaseDevice device,
  required String commandHubId,
}) {
  final theme = inferDeviceTheme(device, context);
  final commandKey = DeviceKeys.commandKey(device);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        snap: true,
        builder: (ctx, scroll) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              decoration: BoxDecoration(color: Theme.of(ctx).cardColor),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // HERO-шапка
                  _Header(
                    theme: theme,
                    title: deviceTitle(device),
                    subtitle: deviceSubtitle(device),
                  ),
                  const SizedBox(height: 16),
                  // Контролы зависят от типа
                  _ControlsArea(
                    theme: theme,
                    device: device,
                    onCommand: (payload) {
                      final ws = ref.read(webSocketNotifierProvider.notifier);
                      ws.updateDeviceLocalState(commandKey, payload);
                      unawaited(
                        ws
                            .sendDeviceCommand(commandHubId, commandKey, payload)
                            .catchError((error, stack) {
                              debugPrint(
                                '[DeviceControls] command error: $error',
                              );
                            }),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _MetricsGrid(theme: theme, device: device),
                  const SizedBox(height: 12),
                  _RawBlock(device: device),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.theme,
    required this.title,
    required this.subtitle,
  });
  final DeviceThemeData theme;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(theme.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  theme.displayType,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (theme.stateText != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                theme.stateText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

typedef _Command = void Function(Map<String, dynamic> payload);

class _ControlsArea extends StatefulWidget {
  const _ControlsArea({
    required this.theme,
    required this.device,
    required this.onCommand,
  });
  final DeviceThemeData theme;
  final BaseDevice device;
  final _Command onCommand;

  @override
  State<_ControlsArea> createState() => _ControlsAreaState();
}

class _ControlsAreaState extends State<_ControlsArea> {
  double? _brightness; // 0..100
  double? _curtainPos; // 0..100
  bool? _power; // ON/OFF для света/реле
  bool? _locked; // замок

  @override
  void initState() {
    super.initState();
    final rd = widget.device.rawData;
    final state = rd['state']?.toString().toUpperCase();
    _power = (state == 'ON' || state == 'OPEN' || state == 'MOTION');
    final b = rd['brightness'];
    if (b is num) _brightness = b.toDouble();
    final p = rd['position'];
    if (p is num) _curtainPos = p.toDouble();
    final lockState =
        (rd['lock_state'] ?? rd['door_lock'])?.toString().toLowerCase();
    _locked = !(lockState == 'unlock' || lockState == 'open');
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.theme.kind;

    switch (k) {
      case DeviceKind.light:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ControlCard(
              child: Row(
                children: [
                  const Icon(Icons.power_settings_new_rounded),
                  const SizedBox(width: 10),
                  const Text(
                    'Состояние',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Switch(
                    value: _power ?? false,
                    onChanged: (v) {
                      setState(() => _power = v);
                      widget.onCommand({'state': v ? 'ON' : 'OFF'});
                    },
                  ),
                ],
              ),
            ),
            if (_brightness != null)
              _ControlCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.brightness_6_outlined),
                        SizedBox(width: 10),
                        Text(
                          'Яркость',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Slider(
                      value: _brightness!.clamp(0, 100),
                      min: 0,
                      max: 100,
                      onChanged: (v) => setState(() => _brightness = v),
                      onChangeEnd:
                          (v) => widget.onCommand({'brightness': v.round()}),
                    ),
                  ],
                ),
              ),
          ],
        );

      case DeviceKind.plug:
        return _ControlCard(
          child: Row(
            children: [
              const Icon(Icons.outlet_outlined),
              const SizedBox(width: 10),
              const Text(
                'Питание',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Switch(
                value: _power ?? false,
                onChanged: (v) {
                  setState(() => _power = v);
                  widget.onCommand({'state': v ? 'ON' : 'OFF'});
                },
              ),
            ],
          ),
        );

      case DeviceKind.curtain:
        return _ControlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.curtains_outlined),
                  SizedBox(width: 10),
                  Text(
                    'Положение штор',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Slider(
                value: (_curtainPos ?? 0).clamp(0, 100),
                min: 0,
                max: 100,
                onChanged: (v) => setState(() => _curtainPos = v),
                onChangeEnd: (v) => widget.onCommand({'position': v.round()}),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    [
                          Text('0%'),
                          Text('${(_curtainPos ?? 0).round()}%'),
                          Text('100%'),
                        ]
                        .map(
                          (e) => Text(
                            e.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
        );

      case DeviceKind.lock:
        return _ControlCard(
          child: Row(
            children: [
              const Icon(Icons.lock_outline),
              const SizedBox(width: 10),
              const Text(
                'Замок',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () {
                  final next = !(_locked ?? true);
                  setState(() => _locked = next);
                  widget.onCommand({'state': next ? 'LOCK' : 'UNLOCK'});
                },
                icon: Icon(
                  (_locked ?? true)
                      ? Icons.lock_outline
                      : Icons.lock_open_outlined,
                ),
                label: Text((_locked ?? true) ? 'Заблокировать' : 'Открыть'),
              ),
            ],
          ),
        );

      default:
        return _ControlCard(
          child: Row(
            children: const [
              Icon(Icons.info_outline),
              SizedBox(width: 10),
              Flexible(child: Text('Для этого типа нет специальных контролов')),
            ],
          ),
        );
    }
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.theme, required this.device});
  final DeviceThemeData theme;
  final BaseDevice device;

  @override
  Widget build(BuildContext context) {
    if (theme.metrics.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Показатели',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              theme.metrics.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        m.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _RawBlock extends StatelessWidget {
  const _RawBlock({required this.device});
  final BaseDevice device;

  @override
  Widget build(BuildContext context) {
    final rd = device.rawData;
    if (rd.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text(
        'Технические данные',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      children: [
        const Divider(),
        ...rd.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${e.value}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
