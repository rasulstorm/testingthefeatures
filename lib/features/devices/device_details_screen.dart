// lib/features/devices/device_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/utils/device_parser.dart';

class DeviceDetailsScreen extends ConsumerStatefulWidget {
  final BaseDevice device;
  final String commandHubId;

  const DeviceDetailsScreen({
    super.key,
    required this.device,
    required this.commandHubId,
  });

  @override
  ConsumerState<DeviceDetailsScreen> createState() =>
      _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends ConsumerState<DeviceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BaseDevice _current;

  @override
  void initState() {
    super.initState();
    _current = widget.device;
    _tabController = TabController(length: 2, vsync: this);
  }

  String parsedTypeName(BaseDevice d) {
    if (d is TempHumiditySensorDevice) return 'Датчик температуры и влажности';
    if (d is MotionSensorDevice) return 'Датчик движения';
    if (d is ContactSensorDevice) return 'Датчик открытия';
    if (d is LeakSensorDevice) return 'Датчик протечки';
    if (d is DimmableLightDevice) return 'Свет (диммируемый)';
    if (d is OnOffSwitchDevice) return 'Реле / Выключатель';
    return 'Устройство';
  }

  void _send(Map<String, dynamic> payload) {
    ref
        .read(webSocketNotifierProvider.notifier)
        .sendDeviceCommand(widget.commandHubId, _current.friendlyName, payload);
  }

  void _updateLocal(Map<String, dynamic> patch) {
    ref
        .read(webSocketNotifierProvider.notifier)
        .updateDeviceLocalState(_current.friendlyName, patch);
    final live =
        ref.read(webSocketNotifierProvider).deviceData[_current.friendlyName];
    setState(() {
      _current =
          live != null
              ? DeviceParser.parse({..._current.rawData, ...live})
              : _current;
    });
  }

  Widget _stateView(BaseDevice d) {
    if (d is TempHumiditySensorDevice) {
      return _InfoCard(
        items: {
          'Температура': '${d.temperature.toStringAsFixed(1)}°C',
          'Влажность': '${d.humidity.round()}%',
          'Связь (LQI)': '${d.linkQuality}',
          if (d.battery != null) 'Батарея': '${d.battery}%',
        },
      );
    }
    if (d is MotionSensorDevice) {
      return _InfoCard(
        items: {
          'Движение': d.hasMotion ? 'Обнаружено' : 'Нет',
          'Связь (LQI)': '${d.linkQuality}',
          if (d.battery != null) 'Батарея': '${d.battery}%',
        },
      );
    }
    if (d is ContactSensorDevice) {
      return _InfoCard(
        items: {
          'Состояние': d.isClosed ? 'Закрыто' : 'Открыто',
          'Связь (LQI)': '${d.linkQuality}',
          if (d.battery != null) 'Батарея': '${d.battery}%',
        },
      );
    }
    if (d is LeakSensorDevice) {
      return _InfoCard(
        items: {
          'Вода': d.hasLeak ? 'Течёт' : 'Нет',
          'Связь (LQI)': '${d.linkQuality}',
        },
      );
    }
    if (d is DimmableLightDevice) {
      final on = d.isOn;
      final percent = ((d.brightness / 254) * 100).round();
      return Column(
        children: [
          SwitchListTile(
            title: const Text('Состояние'),
            value: on,
            onChanged: (v) {
              _send({'state': v ? 'ON' : 'OFF'});
              _updateLocal({'state': v ? 'ON' : 'OFF'});
            },
          ),
          ListTile(
            title: const Text('Яркость'),
            subtitle: Slider(
              min: 1,
              max: 254,
              value: d.brightness.clamp(1, 254).toDouble(),
              onChanged: (val) {
                final b = val.round();
                _send({'brightness': b, 'state': 'ON'});
                _updateLocal({'brightness': b, 'state': 'ON'});
              },
            ),
            trailing: Text('$percent%'),
          ),
        ],
      );
    }
    if (d is OnOffSwitchDevice) {
      return SwitchListTile(
        title: const Text('Состояние'),
        value: d.isOn,
        onChanged: (v) {
          _send({'state': v ? 'ON' : 'OFF'});
          _updateLocal({'state': v ? 'ON' : 'OFF'});
        },
      );
    }
    return const Center(child: Text('Нет данных'));
  }

  @override
  Widget build(BuildContext context) {
    final live =
        ref.watch(webSocketNotifierProvider).deviceData[_current.friendlyName];
    final current =
        live != null
            ? DeviceParser.parse({..._current.rawData, ...live})
            : _current;
    final title = parsedTypeName(current);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryAccent,
          unselectedLabelColor: AppColors.getSecondaryTextColor(context),
          tabs: const [Tab(text: 'Состояние'), Tab(text: 'Настройки')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _stateView(current),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _InfoCard(
              items: {
                'Модель': current.model,
                'Производитель': current.manufacturer,
                'Удобное имя (Zigbee)': current.friendlyName,
                'LQI': '${current.linkQuality}',
                if (current.battery != null) 'Батарея': '${current.battery}%',
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Map<String, String> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        children:
            items.entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: AppStyles.bodyText2(context),
                          ),
                        ),
                        Text(e.value, style: AppStyles.bodyText1(context)),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
