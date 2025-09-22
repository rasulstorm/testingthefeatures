// lib/features/scenarios/widgets/template_card.dart
import 'package:flutter/material.dart';
import '../../scenarios/domain/scenario_models.dart';

class TemplateCard extends StatelessWidget {
  final ScenarioTemplate t;
  final VoidCallback onTap;
  const TemplateCard({super.key, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(t.name),
        subtitle: Text(
          '${t.triggerDeviceType} → ${t.actionDeviceType}${t.version != null ? " v${t.version}" : ""}',
        ),
        onTap: onTap,
      ),
    );
  }
}
