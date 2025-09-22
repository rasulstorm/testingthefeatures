// lib/features/devices/screens/curtain_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/devices/device_catalog.dart';

class CurtainDetailScreen extends StatefulWidget {
  const CurtainDetailScreen({super.key, required this.vm});
  final DeviceCardVm vm;

  @override
  State<CurtainDetailScreen> createState() => _CurtainDetailScreenState();
}

class _CurtainDetailScreenState extends State<CurtainDetailScreen> {
  double pos = 0; // 0..100
  bool moving = false;

  @override
  void initState() {
    super.initState();
    pos = (widget.vm.extra['position'] as num?)?.toDouble() ?? 0;
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _hero(context),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Положение',
                style: TextStyle(color: text, fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '${pos.round()}%',
                style: TextStyle(color: sub, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          Slider(
            value: pos / 100,
            onChanged: (v) => setState(() => pos = v * 100),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _glassBtn(context, Icons.west_rounded, 'Открыть', () {
                  setState(() => moving = true);
                  setState(() => pos = 0);
                  Future.delayed(
                    const Duration(milliseconds: 400),
                    () => setState(() => moving = false),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _glassBtn(context, Icons.east_rounded, 'Закрыть', () {
                  setState(() => moving = true);
                  setState(() => pos = 100);
                  Future.delayed(
                    const Duration(milliseconds: 400),
                    () => setState(() => moving = false),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _badge(
            context,
            moving ? 'Движение' : 'Стоп',
            moving ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: AppColors.glassGradient(ctx),
      border: Border.all(color: AppColors.getGlassBorderColor(ctx)),
    ),
    child: Center(child: Image.asset(widget.vm.asset, height: 110)),
  );

  Widget _glassBtn(BuildContext ctx, IconData i, String t, VoidCallback onTap) {
    final text = AppColors.getPrimaryTextColor(ctx);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppColors.glassGradient(ctx),
          border: Border.all(color: AppColors.getGlassBorderColor(ctx)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: text, size: 18),
            const SizedBox(width: 8),
            Text(t, style: TextStyle(color: text, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext ctx, String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: c.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: c.withOpacity(0.45)),
    ),
    child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w800)),
  );
}
