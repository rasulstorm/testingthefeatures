// lib/features/scenarios/presentation/screens/scenario_editor_screen.dart
// замени твой файл на этот, если уже ставил мою предыдущую версию — это апдейт поверх
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../scenarios/domain/scenario_models.dart';
import '../../../scenarios/data/scenarios_repository.dart';
import 'package:ISS/providers/selected_hub_provider.dart' as hubs;

import '../device_categories.dart';
import '../../ widgets/device_picker_sheet.dart';

class ScenarioEditorScreen extends ConsumerStatefulWidget {
  final Scenario? scenario; // null => создание
  const ScenarioEditorScreen({super.key, this.scenario});

  @override
  ConsumerState<ScenarioEditorScreen> createState() =>
      _ScenarioEditorScreenState();
}

class _ScenarioEditorScreenState extends ConsumerState<ScenarioEditorScreen> {
  late TextEditingController _name;
  bool _enabled = true;
  String _hubId = '';
  final List<ScenarioBlock> _triggers = [];
  final List<ScenarioBlock> _conditions = [];
  final List<ScenarioBlock> _actions = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = widget.scenario?.json;
    _hubId =
        widget.scenario?.json.hubId.isNotEmpty == true
            ? widget.scenario!.json.hubId
            : (ref.read(hubs.selectedHubIdProvider) ?? '');
    _name = TextEditingController(text: s?.name ?? '');
    _enabled = s?.enabled ?? true;
    if (s != null) {
      _triggers.addAll(s.triggers);
      _conditions.addAll(s.conditions);
      _actions.addAll(s.actions);
    } else {
      _conditions.add(
        ScenarioBlock(
          type: 'time.range',
          params: {'from': '22:00', 'to': '06:00'},
        ),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ScenarioJson _buildJson() => ScenarioJson(
    name: _name.text.trim().isEmpty ? 'Новый сценарий' : _name.text.trim(),
    hubId: _hubId,
    enabled: _enabled,
    triggers: _triggers,
    conditions: _conditions,
    actions: _actions,
  );

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(scenariosRepositoryProvider);
      if (widget.scenario == null) {
        await repo.save(_buildJson());
      } else {
        await repo.update(widget.scenario!.id, _buildJson());
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.scenario == null ? 'Сценарий создан' : 'Сценарий обновлён',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ===== Helpers =====

  Future<void> _addTrigger() async {
    final picked = await showDevicePickerSheet(
      context: context,
      ref: ref,
      categories: sensorCategories,
      multi: false,
      title: 'Триггер — выбери датчик',
    );
    if (picked == null || picked.isEmpty) return;
    final d = picked.first;

    // ВАЖНО: deviceId ожидается как "name" (ieee/friendly). Для совместимости кладём ещё и deviceName.
    final block = ScenarioBlock(
      type: 'device.attribute',
      params: {
        'deviceId': d.name,
        'deviceName': d.name,
        'attribute': 'occupancy',
        'op': '==',
        'value': true,
      },
    );
    setState(() => _triggers.add(block));
  }

  Future<void> _addAction() async {
    final picked = await showDevicePickerSheet(
      context: context,
      ref: ref,
      categories: actionCategories,
      multi: true,
      title: 'Действие — выбери устройства',
    );
    if (picked == null || picked.isEmpty) return;

    for (final d in picked) {
      final block = ScenarioBlock(
        type: 'device.set',
        params: {
          'deviceId':
              d.name, // именно name (0x.... / friendly), как в ваших примерах
          'capability': 'switch',
          'value': 'on',
        },
      );
      setState(() => _actions.add(block));
    }
  }

  Future<void> _editTimeRange(int idx) async {
    final curr = _conditions[idx].params;
    TimeOfDay parse(String hhmm) {
      final p = hhmm.split(':');
      return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }

    String format(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final from0 =
        curr['from'] is String
            ? parse(curr['from'])
            : const TimeOfDay(hour: 22, minute: 0);
    final to0 =
        curr['to'] is String
            ? parse(curr['to'])
            : const TimeOfDay(hour: 6, minute: 0);

    final from = await showTimePicker(context: context, initialTime: from0);
    if (from == null) return;
    final to = await showTimePicker(context: context, initialTime: to0);
    if (to == null) return;

    setState(() {
      _conditions[idx] = ScenarioBlock(
        type: 'time.range',
        params: {'from': format(from), 'to': format(to)},
      );
    });
  }

  Future<void> _editAttribute(int idx) async {
    final b = _triggers[idx];
    if (b.type != 'device.attribute') return;

    String attr = (b.params['attribute'] as String?) ?? 'occupancy';
    String op = (b.params['op'] as String?) ?? '==';
    dynamic val = b.params['value'];

    await showDialog(
      context: context,
      builder: (ctx) {
        final attrItems = const [
          'occupancy',
          'contact',
          'temperature',
          'humidity',
        ];
        final opItems = const ['==', '!=', '>', '<', '>=', '<='];
        final valCtrl = TextEditingController(
          text: (val is bool || val == null) ? '' : '$val',
        );

        bool boolVal = val is bool ? val : true;

        void adaptForAttr(String a) {
          // для булевых атрибутов значение логическое, для числовых — текстовое
          if (a == 'occupancy' || a == 'contact') {
            boolVal = val is bool ? val : true;
          } else {
            // numeric
            if (val is! num) val = 0;
          }
        }

        adaptForAttr(attr);

        return AlertDialog(
          title: const Text('Параметры триггера'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: attr,
                decoration: const InputDecoration(labelText: 'Атрибут'),
                items:
                    attrItems
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) {
                  attr = v!;
                  adaptForAttr(attr);
                  (ctx as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: op,
                decoration: const InputDecoration(labelText: 'Оператор'),
                items:
                    opItems
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) {
                  op = v!;
                },
              ),
              const SizedBox(height: 8),
              if (attr == 'occupancy' || attr == 'contact')
                SwitchListTile(
                  title: const Text('Значение'),
                  value: boolVal,
                  onChanged: (v) {
                    boolVal = v;
                  },
                )
              else
                TextField(
                  controller: valCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Значение (число)',
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final newVal =
                    (attr == 'occupancy' || attr == 'contact')
                        ? boolVal
                        : (num.tryParse(valCtrl.text.replaceAll(',', '.')) ??
                            0);
                setState(() {
                  _triggers[idx] = ScenarioBlock(
                    type: 'device.attribute',
                    params: {
                      ...b.params,
                      'attribute': attr,
                      'op': op,
                      'value': newVal,
                    },
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  Widget _blockTile(
    ScenarioBlock b, {
    required VoidCallback onRemove,
    VoidCallback? onTap,
    Color? tint,
  }) {
    String title = b.type;
    String subtitle = '';
    IconData icon = Icons.extension;
    switch (b.type) {
      case 'device.attribute':
        icon = Icons.sensors;
        title = 'Триггер: устройство/атрибут';
        subtitle =
            '${b.params['deviceId'] ?? b.params['deviceName'] ?? "device"} · '
            '${b.params['attribute'] ?? ""} ${b.params['op'] ?? ""} ${b.params['value'] ?? ""}';
        break;
      case 'time.range':
        icon = Icons.schedule;
        title = 'Условие: временной диапазон';
        subtitle = '${b.params['from'] ?? ""} — ${b.params['to'] ?? ""}';
        break;
      case 'device.set':
        icon = Icons.toggle_on;
        title = 'Действие: команда устройству';
        subtitle =
            '${b.params['deviceId'] ?? ""} · ${b.params['capability'] ?? ""}=${b.params['value'] ?? ""}';
        break;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: tint),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onRemove,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _hubId.isNotEmpty && _actions.isNotEmpty && _triggers.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scenario == null
              ? 'Создать сценарий'
              : 'Редактировать сценарий',
        ),
        actions: [
          TextButton(
            onPressed: _busy || !canSubmit ? null : _submit,
            child:
                _busy
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Сохранить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Название сценария'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Включён: ${_enabled ? "Да" : "Нет"}')),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // TRIGGERS
          Row(
            children: [
              Text('Триггеры', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(onPressed: _addTrigger, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 8),
          if (_triggers.isEmpty)
            const Text('Нет триггеров. Добавьте хотя бы один.')
          else
            ..._triggers.asMap().entries.map(
              (e) => _blockTile(
                e.value,
                tint: Theme.of(context).colorScheme.primary,
                onRemove: () => setState(() => _triggers.removeAt(e.key)),
                onTap: () => _editAttribute(e.key),
              ),
            ),

          const SizedBox(height: 16),

          // CONDITIONS
          Row(
            children: [
              Text('Условия', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed:
                    () => setState(
                      () => _conditions.add(
                        ScenarioBlock(
                          type: 'time.range',
                          params: {'from': '22:00', 'to': '06:00'},
                        ),
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_conditions.isEmpty)
            const Text('Без условий')
          else
            ..._conditions.asMap().entries.map(
              (e) => _blockTile(
                e.value,
                tint: Theme.of(context).colorScheme.tertiary,
                onRemove: () => setState(() => _conditions.removeAt(e.key)),
                onTap:
                    e.value.type == 'time.range'
                        ? () => _editTimeRange(e.key)
                        : null,
              ),
            ),

          const SizedBox(height: 16),

          // ACTIONS
          Row(
            children: [
              Text('Действия', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(onPressed: _addAction, icon: const Icon(Icons.add)),
            ],
          ),
          const SizedBox(height: 8),
          if (_actions.isEmpty)
            const Text('Нет действий. Добавьте хотя бы одно.')
          else
            ..._actions.asMap().entries.map(
              (e) => _blockTile(
                e.value,
                tint: Theme.of(context).colorScheme.secondary,
                onRemove: () => setState(() => _actions.removeAt(e.key)),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
