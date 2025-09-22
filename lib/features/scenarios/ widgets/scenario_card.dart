// lib/features/scenarios/widgets/scenario_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../scenarios/domain/scenario_models.dart';

class ScenarioCard extends StatelessWidget {
  final Scenario s;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onToggleEnabled;

  const ScenarioCard({
    super.key,
    required this.s,
    this.onDelete,
    this.onEdit,
    this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = s.json.enabled;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // blur / glass
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(height: 120),
          ),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            title: Text(
              s.json.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '🧲 триггеров: ${s.json.triggers.length}  |  🎯 действий: ${s.json.actions.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: enabled,
                  onChanged: (val) => onToggleEnabled?.call(val),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Редактировать'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Удалить')),
                      ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
