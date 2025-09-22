import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../device_card_base.dart';

class CurtainCard extends StatefulWidget {
  final String deviceId;
  final String room;
  final int position; // 0..100
  final String state; // OPEN/CLOSE/STOP
  final CommandFn onCommand;
  final VoidCallback? onTap;
  const CurtainCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.position,
    required this.state,
    required this.onCommand,
    this.onTap,
  });

  @override
  State<CurtainCard> createState() => _CurtainCardState();
}

class _CurtainCardState extends State<CurtainCard> {
  late double _position = widget.position.clamp(0, 100).toDouble();

  @override
  void didUpdateWidget(covariant CurtainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      _position = widget.position.clamp(0, 100).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final openPercent = (_position / 100).clamp(0.0, 1.0);
    final status = _statusLabel(widget.state, openPercent);

    final overlayImage = Positioned(
      right: -8,
      bottom: -6,
      child: Hero(
        tag: 'img_${widget.deviceId}',
        child: Transform.rotate(
          angle: math.pi / 24,
          child: Image.asset(
            'assets/devices/curtain.png',
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: widget.deviceId,
      title: 'Curtains',
      subtitle: widget.room,
      asset: 'assets/devices/curtain.png',
      gradient: LinearGradient(
        colors: [
          const Color(0xFF6B88FF),
          const Color(0xFF33416C).withValues(alpha: 0.92),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      overlay: overlayImage,
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _Badge(label: '${_position.round()}%'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(child: _CurtainVisualizer(openPercent: openPercent)),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ActionButton(
                      icon: Icons.north_rounded,
                      label: 'Open',
                      onTap: () => _sendState('OPEN', 100),
                    ),
                    _ActionButton(
                      icon: Icons.pause_rounded,
                      label: 'Stop',
                      onTap:
                          () => widget.onCommand(widget.deviceId, {
                            'state': 'STOP',
                          }),
                    ),
                    _ActionButton(
                      icon: Icons.south_rounded,
                      label: 'Close',
                      onTap: () => _sendState('CLOSE', 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Position',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white30,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _position,
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _position = v),
              onChangeEnd:
                  (v) => widget.onCommand(widget.deviceId, {
                    'position': v.round(),
                  }),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String raw, double open) {
    final normalized = raw.toLowerCase();
    if (open >= 0.96) return 'Fully opened';
    if (open <= 0.04) return 'Fully closed';
    if (normalized.contains('open')) return 'Opening';
    if (normalized.contains('close')) return 'Closing';
    return 'Positioning';
  }

  void _sendState(String state, int? target) {
    widget.onCommand(widget.deviceId, {'state': state});
    if (target != null) {
      widget.onCommand(widget.deviceId, {'position': target});
      setState(() => _position = target.toDouble());
    }
  }
}

class _CurtainVisualizer extends StatelessWidget {
  const _CurtainVisualizer({required this.openPercent});
  final double openPercent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: openPercent, end: openPercent),
      duration: const Duration(milliseconds: 350),
      builder: (context, value, _) {
        final factor = (1 - value).clamp(0.1, 0.5);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white12),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: _CurtainPanel(isLeft: true),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: factor,
                  child: _CurtainPanel(isLeft: false),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurtainPanel extends StatelessWidget {
  const _CurtainPanel({required this.isLeft});
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: isLeft ? 0 : 2, right: isLeft ? 2 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isLeft ? 22 : 8),
          right: Radius.circular(isLeft ? 8 : 22),
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFFD7DFF5), Color(0xFFB5C2F1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
