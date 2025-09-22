import 'package:flutter/material.dart';
import '../device_card_base.dart';

class ContactCard extends StatelessWidget {
  final String deviceId;
  final String room;
  final bool closed; // contact==true => закрыто
  final int? battery;
  final VoidCallback? onTap;
  const ContactCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.closed,
    this.battery,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient =
        closed
            ? const LinearGradient(
              colors: [Color(0xFF26C281), Color(0xFF0E664A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
            : const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFF8E2DE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

    final overlayImage = Positioned(
      right: -6,
      top: -10,
      child: Hero(
        tag: 'img_$deviceId',
        child: Image.asset(
          'assets/devices/door.png',
          height: 108,
          fit: BoxFit.contain,
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: deviceId,
      title: 'Door sensor',
      subtitle: room,
      asset: 'assets/devices/door.png',
      gradient: gradient,
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
                    closed ? 'Door closed' : 'Door open',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (battery != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$battery%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Status',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _DoorIllustration(closed: closed),
          const SizedBox(height: 12),
          Text(
            closed ? 'Secure & latched' : 'Please check the doorway',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DoorIllustration extends StatelessWidget {
  const _DoorIllustration({required this.closed});
  final bool closed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(color: Colors.white24),
            ),
          ),
          AnimatedRotation(
            duration: const Duration(milliseconds: 320),
            turns: closed ? 0 : -0.08,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              width: 78,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 18),
              child: Container(
                width: 6,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color:
                      closed
                          ? const Color(0xFF0E664A)
                          : const Color(0xFFD84315),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
