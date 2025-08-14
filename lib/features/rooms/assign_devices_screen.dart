// lib/features/rooms/assign_devices_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/rooms/rooms_providers.dart';
import 'package:ISS/features/rooms/rooms_service.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/models/space_model.dart';
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/utils/device_utils.dart';

class AssignDevicesScreen extends ConsumerStatefulWidget {
  final Room room;
  final String hubId;

  const AssignDevicesScreen({
    super.key,
    required this.room,
    required this.hubId,
  });

  @override
  ConsumerState<AssignDevicesScreen> createState() =>
      _AssignDevicesScreenState();
}

class _AssignDevicesScreenState extends ConsumerState<AssignDevicesScreen> {
  final Set<String> _selected = {};
  bool _loading = false;

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    setState(() => _loading = true);
    try {
      await Future.wait(
        _selected.map(
          (id) => ref
              .read(roomsServiceProvider)
              .assignDeviceToRoom(id, widget.room.id),
        ),
      );
      ref.invalidate(unassignedDevicesProvider(widget.hubId));
      ref.invalidate(roomDevicesProvider(widget.room.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<BaseDevice> unassigned = ref.watch(
      unassignedDevicesProvider(widget.hubId),
    );
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Добавить устройства'),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              onPressed: _selected.isNotEmpty ? _save : null,
              icon: const Icon(Icons.check),
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body:
          unassigned.isEmpty
              ? Center(
                child: Text(
                  'Нет свободных устройств',
                  style: AppStyles.bodyText2(context),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: unassigned.length,
                itemBuilder: (_, i) {
                  final d = unassigned[i];
                  final sel = _selected.contains(d.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.getCardBackgroundColor(context),
                    child: CheckboxListTile(
                      value: sel,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(d.id);
                          } else {
                            _selected.remove(d.id);
                          }
                        });
                      },
                      title: Text(
                        d.friendlyName,
                        style: AppStyles.bodyText1(context),
                      ),
                      subtitle: Text(
                        d.model,
                        style: AppStyles.caption(context),
                      ),
                      secondary: Icon(
                        DeviceUtils.getIconForDevice(d),
                        color: AppColors.getSecondaryTextColor(context),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primaryAccent,
                      checkColor: AppColors.textColorDark,
                    ),
                  );
                },
              ),
    );
  }
}
