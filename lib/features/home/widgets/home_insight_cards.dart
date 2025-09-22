import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ISS/appstyles.dart';

class HomeWeatherCard extends StatelessWidget {
  const HomeWeatherCard({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.location,
    this.description,
    this.isLoading = false,
  });

  final double? temperature;
  final double? humidity;
  final String location;
  final String? description;
  final bool isLoading;

  IconData _iconForCondition() {
    final text = description?.toLowerCase() ?? '';
    if (text.contains('гроза')) return Icons.flash_on_rounded;
    if (text.contains('дожд')) return Icons.grain_rounded;
    if (text.contains('снег')) return Icons.ac_unit_rounded;
    if (text.contains('туман')) return Icons.blur_on_rounded;
    if (text.contains('облач')) return Icons.wb_cloudy_rounded;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tempText =
        temperature != null ? '${temperature!.toStringAsFixed(1)}°C' : '—°C';
    final humidityText =
        humidity != null ? '${humidity!.toStringAsFixed(0)}% RH' : '—% RH';
    final now = DateTime.now();
    final dateLabel = DateFormat.MMMd().format(now);
    final icon = _iconForCondition();

    return Container(
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F1F25), Color(0xFF2F3B53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(
              icon,
              size: 46,
              color:
                  icon == Icons.wb_sunny_rounded ? Colors.amber : Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  Text(
                    tempText,
                    style: AppStyles.headline4(
                      context,
                    ).copyWith(color: Colors.white, fontSize: 30),
                  ),
                  const SizedBox(height: 2),
                  if (description != null) ...[
                    Text(
                      description!,
                      style: AppStyles.headline5(
                        context,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 1),
                  ],
                  Text(
                    humidityText,
                    style: AppStyles.headline5(
                      context,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dateLabel,
                style: AppStyles.bodyText2(
                  context,
                ).copyWith(color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 90,
                child: Text(
                  location.isNotEmpty ? location : 'Локация неизвестна',
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.caption(
                    context,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeEnergyCard extends StatelessWidget {
  const HomeEnergyCard({
    super.key,
    required this.totalDevices,
    required this.activeDevices,
  });

  final int totalDevices;
  final int activeDevices;

  @override
  Widget build(BuildContext context) {
    final savings =
        totalDevices == 0
            ? 0
            : ((activeDevices / totalDevices) * 100).clamp(0, 100).round();

    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE29F), Color(0xFFFFC76B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Активные устройства',
                  style: AppStyles.headline4(context).copyWith(
                    color: const Color(0xFF2D1F00),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$activeDevices из $totalDevices',
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: const Color(0xFF5A4300)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Энергия оптимизирована на $savings%',
                  style: AppStyles.caption(
                    context,
                  ).copyWith(color: const Color(0xFF5A4300)),
                ),
              ],
            ),
          ),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.32),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF2D1F00),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}
