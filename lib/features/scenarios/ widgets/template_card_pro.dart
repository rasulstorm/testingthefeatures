// lib/features/scenarios/widgets/template_card_pro.dart
import 'package:flutter/material.dart';
import '../domain/scenario_models.dart';
import '../presentation/icons_theme.dart';

class TemplateCardPro extends StatelessWidget {
  final ScenarioTemplate t;
  final VoidCallback onTap;
  const TemplateCardPro({super.key, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grad = templateGradient(t.triggerDeviceType);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad.colors,
              begin: grad.begin,
              end: grad.end,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  templateIcon(t.actionDeviceType),
                  size: 96,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: Icon(
                        templateIcon(t.triggerDeviceType),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${t.triggerDeviceType} → ${t.actionDeviceType}${t.version != null ? " · v${t.version}" : ""}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
