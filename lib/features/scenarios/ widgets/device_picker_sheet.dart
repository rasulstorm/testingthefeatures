// lib/features/scenarios/presentation/widgets/device_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/scenarios_repository.dart';
import '../domain/scenario_models.dart';
import '../presentation/device_categories.dart';

Future<List<DeviceSummary>?> showDevicePickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<DeviceCategoryDef> categories,
  bool multi = true,
  String title = 'Выбор устройств',
}) {
  return showModalBottomSheet<List<DeviceSummary>>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder:
        (_) => _DevicePickerSheet(
          categories: categories,
          multi: multi,
          ref: ref,
          title: title,
        ),
  );
}

class _DevicePickerSheet extends StatefulWidget {
  final List<DeviceCategoryDef> categories;
  final bool multi;
  final WidgetRef ref;
  final String title;
  const _DevicePickerSheet({
    required this.categories,
    required this.multi,
    required this.ref,
    required this.title,
  });

  @override
  State<_DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<_DevicePickerSheet> {
  late DeviceCategoryDef _selected;
  List<DeviceSummary> _items = [];
  final List<DeviceSummary> _chosen = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = widget.categories.first;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await widget.ref
          .read(scenariosRepositoryProvider)
          .devicesByCategory(_selected.apiName);
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Iterable<DeviceSummary> _filtered() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where(
      (d) =>
          d.displayTitle.toLowerCase().contains(q) ||
          d.name.toLowerCase().contains(q) ||
          (d.roomName ?? '').toLowerCase().contains(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.check),
              onPressed:
                  _chosen.isEmpty && widget.multi
                      ? null
                      : () => Navigator.pop(
                        context,
                        _chosen.isEmpty ? null : _chosen,
                      ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children:
                  widget.categories.map((c) {
                    final sel = c.apiName == _selected.apiName;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          children: [
                            Icon(c.icon, size: 16),
                            const SizedBox(width: 6),
                            Text(c.label),
                          ],
                        ),
                        selected: sel,
                        onSelected: (_) async {
                          setState(() => _selected = c);
                          await _load();
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Поиск по имени/комнате',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children:
                  _filtered().map((d) {
                    final selected = _chosen.any((x) => x.id == d.id);
                    final subtitle = [
                      if (d.roomName != null) d.roomName!,
                      d.deviceCategory,
                      if (d.lastUpdate != null)
                        'обновл: ${d.lastUpdate!.toLocal()}',
                    ].join(' • ');
                    final tile = ListTile(
                      leading: Icon(
                        Icons.memory,
                        color:
                            selected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      title: Text(d.displayTitle),
                      subtitle: Text(subtitle),
                      trailing:
                          widget.multi
                              ? Checkbox(
                                value: selected,
                                onChanged: (_) {
                                  setState(() {
                                    if (selected) {
                                      _chosen.removeWhere((x) => x.id == d.id);
                                    } else {
                                      _chosen.add(d);
                                    }
                                  });
                                },
                              )
                              : null,
                      onTap: () {
                        if (widget.multi) {
                          setState(() {
                            if (selected) {
                              _chosen.removeWhere((x) => x.id == d.id);
                            } else {
                              _chosen.add(d);
                            }
                          });
                        } else {
                          Navigator.pop(context, [d]);
                        }
                      },
                    );
                    return Card(child: tile);
                  }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
