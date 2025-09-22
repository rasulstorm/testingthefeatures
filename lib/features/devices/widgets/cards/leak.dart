import 'package:flutter/material.dart';
import '../device_card_base.dart';

class LeakCard extends StatelessWidget {
  final String deviceId;
  final String room;
  final bool leak;
  final VoidCallback? onTap;
  const LeakCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.leak,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overlayImage = Positioned(
      right: -6,
      top: -12,
      child: Hero(
        tag: 'img_$deviceId',
        child: Image.asset(
          'assets/devices/leak.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: deviceId,
      title: 'Leak sensor',
      subtitle: room,
      asset: 'assets/devices/leak.png',
      gradient:
          leak
              ? const LinearGradient(
                colors: [Color(0xFF0F9BEB), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
              : const LinearGradient(
                colors: [Color(0xFF546E7A), Color(0xFF24323A)],
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
                    leak ? 'Water detected!' : 'Dry & safe',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                leak ? Icons.warning_amber_rounded : Icons.shield_outlined,
                color: Colors.white,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 110,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: leak ? 0.25 : 0.12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.water_drop,
                      size: 42,
                      color:
                          leak
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            leak
                                ? const [Color(0xAA29B6F6), Color(0xFF1565C0)]
                                : const [Color(0x5529B6F6), Color(0x332196F3)],
                      ),
                    ),
                  ),
                ),
                if (leak)
                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.circle, size: 6, color: Colors.white70),
                        SizedBox(width: 6),
                        Icon(Icons.circle, size: 6, color: Colors.white54),
                        SizedBox(width: 6),
                        Icon(Icons.circle, size: 6, color: Colors.white38),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            leak
                ? 'Alarm sent to prevent flooding'
                : 'Monitoring humidity levels',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
