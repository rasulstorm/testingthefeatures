import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../device_card_base.dart';

class EnvCard extends StatelessWidget {
  final String deviceId;
  final String room;
  final num? t, h, lux;
  final VoidCallback? onTap;
  const EnvCard({
    super.key,
    required this.deviceId,
    required this.room,
    this.t,
    this.h,
    this.lux,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double? temperature = t?.toDouble();
    final double? humidity = h?.toDouble();
    final double? illuminance = lux?.toDouble();

    final overlayImage = Positioned(
      right: -10,
      top: -14,
      child: Hero(
        tag: 'img_$deviceId',
        child: Image.asset(
          'assets/devices/env.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: deviceId,
      title: 'Indoor climate',
      subtitle: room,
      asset: 'assets/devices/env.png',
      gradient: const LinearGradient(
        colors: [Color(0xFF39A2DB), Color(0xFF154170)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      overlay: overlayImage,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      temperature != null
                          ? '${temperature.toStringAsFixed(1)}°C'
                          : 'No data',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (humidity != null)
                      Text(
                        'Humidity ${humidity.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              _ClimateGauge(temperature: temperature, humidity: humidity),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (illuminance != null)
                _InfoPill(
                  icon: Icons.wb_sunny_outlined,
                  label: '${illuminance.toStringAsFixed(0)} lx',
                ),
              if (temperature != null)
                _InfoPill(
                  icon: Icons.thermostat_outlined,
                  label: 'Feels ${_comfortLabel(temperature, humidity)}',
                ),
              _InfoPill(
                icon: Icons.home_rounded,
                label:
                    humidity == null ? 'Humidity —' : _humidityLabel(humidity),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _comfortLabel(double temp, double? humidity) {
    if (humidity == null) {
      if (temp < 20) return 'cool';
      if (temp > 25) return 'warm';
      return 'balanced';
    }
    if (temp < 19 || humidity > 70) return 'cool';
    if (temp > 26 || humidity < 30) return 'warm';
    return 'balanced';
  }

  String _humidityLabel(double humidity) {
    if (humidity < 30) return 'Dry air';
    if (humidity > 60) return 'Humid';
    return 'Comfort';
  }
}

class _ClimateGauge extends StatelessWidget {
  const _ClimateGauge({this.temperature, this.humidity});
  final double? temperature;
  final double? humidity;

  @override
  Widget build(BuildContext context) {
    final humidityValue = (humidity ?? 0).clamp(0, 100);
    final progress = humidity != null ? humidityValue / 100 : 0.0;

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Transform.rotate(
                angle: -math.pi / 2,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFB3E5FC),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  color: Colors.white.withValues(alpha: 0.85),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  humidity != null
                      ? '${humidityValue.toStringAsFixed(0)}%'
                      : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
