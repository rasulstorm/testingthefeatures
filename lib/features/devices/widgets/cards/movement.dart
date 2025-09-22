import 'package:flutter/material.dart';
import '../device_card_base.dart';

class MotionCard extends StatelessWidget {
  final String deviceId;
  final String room;
  final bool motion;
  final int? illuminance;
  final int? battery;
  final VoidCallback? onTap;
  const MotionCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.motion,
    this.illuminance,
    this.battery,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overlayImage = Positioned(
      right: -10,
      bottom: -8,
      child: Hero(
        tag: 'img_$deviceId',
        child: Image.asset(
          'assets/devices/movement.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: deviceId,
      title: 'Motion sensor',
      subtitle: room,
      asset: 'assets/devices/movement.png',
      gradient: const LinearGradient(
        colors: [Color(0xFF8E67E8), Color(0xFF2F2D6A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      overlay: overlayImage,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
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
                  const SizedBox(height: 4),
                  Text(
                    motion ? 'Movement spotted' : 'All calm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _StatusDot(active: motion),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RadarCircle(radius: 110, opacity: motion ? 0.25 : 0.12),
                _RadarCircle(radius: 76, opacity: motion ? 0.35 : 0.18),
                _RadarCircle(radius: 48, opacity: motion ? 0.5 : 0.25),
                Icon(
                  motion ? Icons.sensors : Icons.sensors_off,
                  color: Colors.white,
                  size: 36,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (illuminance != null)
                _InfoChip(
                  icon: Icons.wb_sunny_outlined,
                  label: '${illuminance!} lx',
                ),
              if (battery != null)
                _InfoChip(icon: Icons.battery_std, label: '$battery% battery'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RadarCircle extends StatelessWidget {
  const _RadarCircle({required this.radius, required this.opacity});
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 20,
      decoration: BoxDecoration(
        color:
            active
                ? Colors.greenAccent.withValues(alpha: 0.35)
                : Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? Colors.greenAccent : Colors.white24),
      ),
      alignment: Alignment.center,
      child: Text(
        active ? 'ACTIVE' : 'IDLE',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
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
