import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../device_card_base.dart';

class DimmerCard extends StatefulWidget {
  final String deviceId;
  final String room;
  final int brightness; // 0..254/100
  final bool isOn;
  final double? colorTemp;
  final double? hue;
  final double? saturation;
  final CommandFn onCommand;
  final VoidCallback? onTap;

  const DimmerCard({
    super.key,
    required this.deviceId,
    required this.room,
    required this.brightness,
    required this.isOn,
    required this.onCommand,
    this.colorTemp,
    this.hue,
    this.saturation,
    this.onTap,
  });

  @override
  State<DimmerCard> createState() => _DimmerCardState();
}

class _DimmerCardState extends State<DimmerCard> {
  static const _colorPresets = [
    Color(0xFFFFB74D),
    Color(0xFFF06292),
    Color(0xFF4DD0E1),
    Color(0xFFBA68C8),
  ];

  static const _tonePresets = [
    _TonePreset('Warm', 370),
    _TonePreset('Neutral', 250),
    _TonePreset('Cold', 153),
  ];

  late double _brightness = widget.brightness.clamp(0, 254).toDouble();
  late bool _power = widget.isOn;
  Color? _selectedColor;
  double? _colorTemp;

  @override
  void initState() {
    super.initState();
    _colorTemp = widget.colorTemp;
    final hue = widget.hue;
    final sat = widget.saturation;
    if (hue != null && sat != null) {
      _selectedColor =
          HSVColor.fromAHSV(1, hue, (sat / 100).clamp(0, 1), 1).toColor();
    }
  }

  @override
  void didUpdateWidget(covariant DimmerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      _brightness = widget.brightness.clamp(0, 254).toDouble();
    }
    if (oldWidget.isOn != widget.isOn) {
      _power = widget.isOn;
    }
    if (widget.hue != oldWidget.hue || widget.saturation != oldWidget.saturation) {
      final hue = widget.hue;
      final sat = widget.saturation;
      if (hue != null && sat != null) {
        _selectedColor =
            HSVColor.fromAHSV(1, hue, (sat / 100).clamp(0, 1), 1).toColor();
        _colorTemp = null;
      }
    }
    if (widget.colorTemp != oldWidget.colorTemp) {
      _colorTemp = widget.colorTemp;
      if (widget.colorTemp != null) {
        _selectedColor = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        _accentColor.withValues(alpha: _power ? 0.95 : 0.7),
        _darken(_accentColor, _power ? 0.55 : 0.75),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final cardText = Colors.white.withValues(alpha: 0.92);
    final subText = Colors.white70;

    final overlayImage = Positioned(
      right: -16,
      top: -12,
      child: Hero(
        tag: 'img_${widget.deviceId}',
        child: Opacity(
          opacity: _power ? 1 : 0.6,
          child: Image.asset(
            'assets/devices/lamp.png',
            height: 130,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    return DeviceCardBase(
      deviceId: widget.deviceId,
      title: 'Smart light',
      subtitle: widget.room,
      asset: 'assets/devices/lamp.png',
      gradient: gradient,
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
                      widget.room,
                      style: TextStyle(
                        color: subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _power ? 'Lights on' : 'Lights off',
                      style: TextStyle(
                        color: cardText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.85,
                alignment: Alignment.centerRight,
                child: CupertinoSwitch(
                  value: _power,
                  onChanged: _onToggle,
                  inactiveTrackColor: Colors.white24,
                  activeTrackColor: Colors.white,
                  thumbColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _GlowingDot(color: _accentColor),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intensity',
                      style: TextStyle(
                        color: subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(_brightness / 254 * 100).round()}%',
                      style: TextStyle(
                        color: cardText,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.bolt_rounded, color: cardText, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _brightness,
              min: 0,
              max: 254,
              onChanged:
                  (v) => setState(() {
                    _brightness = v;
                    if (!_power && v > 0) _power = true;
                  }),
              onChangeEnd: (v) => _sendCommand({'brightness': v.round()}),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Quick colours',
            style: TextStyle(
              color: cardText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children:
                _colorPresets
                    .map(
                      (c) => _ColorChip(
                        color: c,
                        selected:
                            _selectedColor != null &&
                            _isSameColor(_selectedColor!, c),
                        onTap: () => _applyColor(c),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Tone glow',
            style: TextStyle(color: cardText, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children:
                _tonePresets
                    .map(
                      (preset) => Expanded(
                        child: _ToneButton(
                          label: preset.label,
                          selected: _isToneSelected(preset),
                          onTap: () => _applyTone(preset),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Color get _accentColor {
    final color = _selectedColor;
    if (color != null) return color;
    final temp = _colorTemp;
    if (temp != null) {
      if (temp <= 180) return const Color(0xFFFFB74D);
      if (temp <= 260) return const Color(0xFFFFE082);
      return const Color(0xFFB3E5FC);
    }
    return const Color(0xFFFFC107);
  }

  void _onToggle(bool value) {
    setState(() => _power = value);
    _sendCommand({'state': value ? 'ON' : 'OFF'});
  }

  void _sendCommand(Map<String, dynamic> payload) {
    final map = {'state': _power ? 'ON' : 'OFF', ...payload};
    widget.onCommand(widget.deviceId, map);
  }

  void _applyColor(Color color) {
    setState(() {
      _selectedColor = color;
      _colorTemp = null;
      _power = true;
    });
    widget.onCommand(widget.deviceId, {
      'state': 'ON',
      'color_mode': 'color',
      'brightness': _brightness.round(),
      'color': _toRgb(color),
    });
  }

  void _applyTone(_TonePreset preset) {
    setState(() {
      _colorTemp = preset.value.toDouble();
      _selectedColor = null;
      _power = true;
    });
    widget.onCommand(widget.deviceId, {
      'state': 'ON',
      'color_mode': 'color_temp',
      'color_temp': preset.value,
    });
  }

  bool _isToneSelected(_TonePreset preset) {
    if (_selectedColor != null) return false;
    final temp = _colorTemp;
    if (temp == null) return false;
    return (temp - preset.value).abs() <= 30;
  }

  Map<String, int> _toRgb(Color color) {
    return {
      'r': _channelToInt(color.r),
      'g': _channelToInt(color.g),
      'b': _channelToInt(color.b),
    };
  }

  int _channelToInt(double component) {
    final scaled = (component * 255.0).round();
    if (scaled < 0) return 0;
    if (scaled > 255) return 255;
    return scaled;
  }

  Color _darken(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  bool _isSameColor(Color a, Color b) {
    final ar = _channelToInt(a.r);
    final ag = _channelToInt(a.g);
    final ab = _channelToInt(a.b);
    final br = _channelToInt(b.r);
    final bg = _channelToInt(b.g);
    final bb = _channelToInt(b.b);
    return (ar - br).abs() < 5 && (ag - bg).abs() < 5 && (ab - bb).abs() < 5;
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? 36 : 32,
        height: selected ? 36 : 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: selected ? 3 : 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingDot extends StatelessWidget {
  const _GlowingDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.1)]),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _ToneButton extends StatelessWidget {
  const _ToneButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white12,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TonePreset {
  const _TonePreset(this.label, this.value);
  final String label;
  final int value;
}
