import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/models/device_models.dart';
import 'device_theme.dart';
import 'device_controls_sheet.dart';

class DeviceCardPro extends ConsumerWidget {
  const DeviceCardPro({
    super.key,
    required this.device,
    required this.commandHubId,
  });

  final BaseDevice device;
  final String commandHubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = inferDeviceTheme(device, context);
    final title = deviceTitle(device);
    final subtitle = deviceSubtitle(device);

    return InkWell(
      onTap:
          () => showDeviceControlsSheet(
            context: context,
            ref: ref,
            device: device,
            commandHubId: commandHubId,
          ),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(theme.icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                if (theme.stateText != null && theme.stateText!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      theme.stateText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // title/subtitle
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 12.5,
                ),
              ),

            const Spacer(),

            // metrics
            if (theme.metrics.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    theme.metrics.take(3).map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(m.icon, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              m.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
