// lib/features/devices/screens/sensor_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/devices/device_catalog.dart';

class SensorDetailScreen extends StatelessWidget {
  const SensorDetailScreen({super.key, required this.vm});
  final DeviceCardVm vm;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.getPrimaryTextColor(context);
    final sub = AppColors.getSecondaryTextColor(context);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(vm.title, style: TextStyle(color: text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppColors.glassGradient(context),
              border: Border.all(color: AppColors.getGlassBorderColor(context)),
            ),
            child: Row(
              children: [
                Image.asset(vm.asset, height: 70),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline(vm),
                        style: TextStyle(
                          color: vm.disconnected ? Colors.redAccent : text,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_subtitle(vm), style: TextStyle(color: sub)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _signalPill(context, vm.linkquality, vm.disconnected),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (vm.kind == DeviceUiKind.climate) ...[
            _metric(
              context,
              '${_fmt(vm.extra['temperature'])}°',
              'Температура',
            ),
            const SizedBox(height: 10),
            _metric(context, '${_fmt(vm.extra['humidity'])}%', 'Влажность'),
            const SizedBox(height: 10),
            _metric(
              context,
              '${_fmt(vm.extra['illuminance'])} lx',
              'Освещенность',
            ),
          ] else ...[
            _info(context, 'ID', vm.deviceId),
            _info(context, 'Комната', vm.roomName.isEmpty ? '—' : vm.roomName),
            _info(context, 'Статус', vm.extra['status']?.toString() ?? '—'),
          ],
        ],
      ),
    );
  }

  String _headline(DeviceCardVm vm) =>
      vm.disconnected ? 'Связь потеряна' : 'Подключено';

  String _subtitle(DeviceCardVm vm) {
    if (vm.disconnected) {
      return 'Нет данных. Проверьте батарею/расстояние до хаба.';
    }
    final lq = vm.linkquality ?? 0;
    return 'Сигнал: $lq • Статус: ${vm.extra['status'] ?? 'н/д'}';
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is num) return (v.toStringAsFixed(1)).replaceAll('.0', '');
    return v.toString();
  }

  Widget _metric(BuildContext ctx, String value, String label) {
    final text = AppColors.getPrimaryTextColor(ctx);
    final sub = AppColors.getSecondaryTextColor(ctx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppColors.glassGradient(ctx),
        border: Border.all(color: AppColors.getGlassBorderColor(ctx)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: sub, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(BuildContext ctx, String l, String v) {
    final sub = AppColors.getSecondaryTextColor(ctx);
    final text = AppColors.getPrimaryTextColor(ctx);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.getGlassFillColor(ctx),
        border: Border.all(color: AppColors.getGlassBorderColor(ctx)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: sub, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: text, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalPill(BuildContext ctx, int? lq, bool disc) {
    Color c;
    String t;
    if (disc || lq == null) {
      c = Colors.grey;
      t = 'нет связи';
    } else if (lq < 60) {
      c = Colors.redAccent;
      t = 'низкий';
    } else if (lq < 110) {
      c = Colors.orangeAccent;
      t = 'средний';
    } else {
      c = Colors.green;
      t = 'хороший';
    }
    final bg = (AppColors.isDarkMode(ctx) ? Colors.white : Colors.black)
        .withOpacity(0.06);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_rounded, color: c, size: 16),
          const SizedBox(width: 6),
          Text(
            t,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
