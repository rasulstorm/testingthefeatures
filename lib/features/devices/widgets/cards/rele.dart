import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../device_card_base.dart';

class RelayCard extends StatefulWidget {
  final String deviceId;
  final String room;
  final bool isOn;
  final num power, voltage, current;
  final CommandFn onCommand;
  final VoidCallback? onTap;
  const RelayCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.isOn,
    required this.power,
    required this.voltage,
    required this.current,
    required this.onCommand,
    this.onTap,
  });

  @override
  State<RelayCard> createState() => _RelayCardState();
}

class _RelayCardState extends State<RelayCard> {
  late bool _on = widget.isOn;

  @override
  void didUpdateWidget(RelayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOn != widget.isOn) {
      _on = widget.isOn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final power = widget.power.toDouble();
    final voltage = widget.voltage.toDouble();
    final current = widget.current.toDouble();
    final usage = (power / 2500).clamp(0.0, 1.0);

    final overlayImage = Positioned(
      right: -16,
      top: -10,
      child: Hero(
        tag: 'img_${widget.deviceId}',
        child: Image.asset(
          'assets/devices/relay.png',
          height: 110,
          fit: BoxFit.contain,
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: widget.deviceId,
      title: 'Smart socket',
      subtitle: widget.room,
      asset: 'assets/devices/relay.png',
      gradient: const LinearGradient(
        colors: [Color(0xFF64C987), Color(0xFF1F4440)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      overlay: overlayImage,
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 4),
                  Text(
                    _on ? 'Power on' : 'Power off',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.9,
                child: CupertinoSwitch(
                  value: _on,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  onChanged: (value) {
                    setState(() => _on = value);
                    widget.onCommand(widget.deviceId, {
                      'state': value ? 'ON' : 'OFF',
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Instant power',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${power.toStringAsFixed(power >= 10 ? 0 : 1)} W',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _on ? usage : 0,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFCFFFE2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetricTile(
                icon: Icons.flash_on_rounded,
                label: 'Voltage',
                value: '${voltage.toStringAsFixed(0)} V',
              ),
              const SizedBox(width: 12),
              _MetricTile(
                icon: Icons.developer_board_rounded,
                label: 'Current',
                value: '${current.toStringAsFixed(current >= 10 ? 0 : 2)} A',
              ),
              const SizedBox(width: 12),
              _MetricTile(
                icon: Icons.shield_outlined,
                label: 'State',
                value: _on ? 'Active' : 'Standby',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
