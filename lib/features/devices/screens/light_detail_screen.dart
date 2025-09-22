// lib/features/devices/screens/light_detail_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/devices/device_catalog.dart';

class LightDetailScreen extends StatefulWidget {
  const LightDetailScreen({super.key, required this.vm});
  final DeviceCardVm vm;

  @override
  State<LightDetailScreen> createState() => _LightDetailScreenState();
}

class _LightDetailScreenState extends State<LightDetailScreen> {
  bool power = true;
  double intensity = 0.65; // 0..1
  double hue = 190; // 0..360
  bool cold = true;

  @override
  void initState() {
    super.initState();
    power = (widget.vm.extra['on'] as bool?) ?? true;
    final br = (widget.vm.extra['brightness'] as num?)?.toInt();
    if (br != null) intensity = (br / 254).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppColors.getPrimaryTextColor(context);
    final sub = AppColors.getSecondaryTextColor(context);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.vm.title, style: TextStyle(color: text)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: AppColors.glassGradient(context),
              border: Border.all(color: AppColors.getGlassBorderColor(context)),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    top: 54,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: power ? intensity.clamp(0.3, 1.0) : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.lightBlueAccent.withOpacity(0.75),
                                Colors.lightBlueAccent.withOpacity(0.12),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Image.asset(widget.vm.asset, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          _Section(
            title: 'Power',
            trailing: CupertinoSwitch(
              value: power,
              onChanged: (v) => setState(() => power = v),
            ),
          ),
          _Section(title: 'Tone Glow'),
          const SizedBox(height: 8),
          _Segment(
            left: 'Warm',
            right: 'Cold',
            isRight: cold,
            onChanged: (v) => setState(() => cold = v),
          ),

          const SizedBox(height: 22),
          _Section(
            title: 'Intensity',
            trailing: Text(
              '${(intensity * 100).round()}%',
              style: TextStyle(color: sub, fontWeight: FontWeight.w800),
            ),
          ),
          Slider(
            value: intensity,
            min: 0,
            max: 1,
            onChanged: (v) => setState(() => intensity = v),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final text = AppColors.getPrimaryTextColor(context);
    return Row(
      children: [
        Text(title, style: TextStyle(color: text, fontWeight: FontWeight.w900)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.left,
    required this.right,
    required this.isRight,
    required this.onChanged,
  });
  final String left, right;
  final bool isRight;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getGlassBorderColor(context)),
      ),
      child: Row(
        children: [
          _btn(context, left, !isRight, () => onChanged(false)),
          _btn(context, right, isRight, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _btn(BuildContext ctx, String label, bool sel, VoidCallback tap) {
    final textSel = AppColors.getPrimaryTextColor(ctx);
    final textDef = AppColors.getSecondaryTextColor(ctx);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: tap,
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? textSel.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: sel ? textSel : textDef,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
