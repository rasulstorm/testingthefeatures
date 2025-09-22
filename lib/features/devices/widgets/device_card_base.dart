import 'package:flutter/material.dart';

typedef CommandFn =
    void Function(String deviceId, Map<String, dynamic> payload);

class DeviceCardBase extends StatelessWidget {
  final String deviceId;
  final String title;
  final String subtitle;
  final String asset;
  final Gradient gradient;
  final Widget? trailing; // например, тумблер
  final VoidCallback? onTap;
  final List<Widget>? bottom; // мини-параметры (чипы/лейблы)
  final Widget? child; // полностью кастомный контент
  final Widget? overlay; // свои декоры поверх контента
  final EdgeInsetsGeometry padding;

  const DeviceCardBase({
    super.key,
    required this.deviceId,
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.gradient,
    this.trailing,
    this.onTap,
    this.bottom,
    this.child,
    this.overlay,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? _buildDefaultContent();
    final Widget? overlayWidget = overlay ?? _buildDefaultOverlay();

    final card = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Padding(padding: padding, child: content)),
          if (overlayWidget != null) overlayWidget,
        ],
      ),
    );

    return Hero(
      tag: 'card_$deviceId',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          child: card,
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        if (bottom != null) Wrap(spacing: 8, runSpacing: 8, children: bottom!),
      ],
    );
  }

  Widget? _buildDefaultOverlay() {
    if (asset.isEmpty) return null;
    return Positioned(
      right: -6,
      bottom: -4,
      child: Hero(
        tag: 'img_$deviceId',
        child: Image.asset(asset, height: 92, fit: BoxFit.contain),
      ),
    );
  }
}
