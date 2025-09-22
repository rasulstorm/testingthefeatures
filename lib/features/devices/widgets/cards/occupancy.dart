import 'package:flutter/material.dart';
import '../device_card_base.dart';

class PresenceCard extends StatelessWidget {
  final String deviceId;
  final String room;
  final bool presence;
  final int? distance; // target_distance, мм
  final VoidCallback? onTap;
  const PresenceCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.presence,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double? meters = distance != null ? distance! / 1000 : null;

    final overlayImage = Positioned(
      right: -10,
      top: -12,
      child: Hero(
        tag: 'img_$deviceId',
        child: Image.asset(
          'assets/devices/presence.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: deviceId,
      title: 'Presence radar',
      subtitle: room,
      asset: 'assets/devices/presence.png',
      gradient: const LinearGradient(
        colors: [Color(0xFF36C7B7), Color(0xFF145B59)],
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
                    presence ? 'Someone is here' : 'Area clear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      presence
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        presence
                            ? Colors.white70
                            : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  presence ? 'PRESENT' : 'IDLE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: presence ? 0.35 : 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white30),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    presence
                        ? Icons.psychology_rounded
                        : Icons.psychology_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                if (meters != null)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${meters.toStringAsFixed(1)} m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            presence ? 'Micro motion detected' : 'Monitoring for presence…',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
