// lib/features/rooms/rooms_and_devices_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/providers/hubs_provider.dart';
import 'package:ISS/providers/selected_hub_provider.dart';
import 'package:ISS/features/rooms/rooms_providers.dart';
import 'package:ISS/features/rooms/rooms_service.dart';
import 'package:ISS/models/space_model.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/utils/device_parser.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/features/devices/device_details_screen.dart';

class RoomsAndDevicesScreen extends ConsumerWidget {
  const RoomsAndDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentHub = ref.watch(currentHubProvider);
    final space =
        currentHub == null
            ? null
            : ref.watch(spaceForHubProvider(currentHub.commandHubId));

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body:
          currentHub == null
              ? const Center(child: CircularProgressIndicator())
              : _Body(hubCommandId: currentHub.commandHubId),
      floatingActionButton:
          (currentHub == null || space == null)
              ? null
              : FloatingActionButton.extended(
                onPressed:
                    () => _createRoomFlow(
                      context,
                      ref,
                      space.id,
                      currentHub.commandHubId,
                    ),
                icon: const Icon(Icons.add),
                label: const Text('Новая комната'),
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textColorDark,
              ),
    );
  }

  Future<void> _createRoomFlow(
    BuildContext context,
    WidgetRef ref,
    String spaceId,
    String hubCommandId,
  ) async {
    final service = ref.read(roomsServiceProvider);
    final controller = TextEditingController();

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            title: const Text('Создать комнату'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Название комнаты'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: AppStyles.primaryButtonStyle,
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  await service.createRoom(spaceId, name);
                  // тянем свежий getObjects, чтобы rooms обновились
                  await ref.refresh(hubsProvider.future);
                },
                child: const Text('Создать'),
              ),
            ],
          ),
    );
  }
}

class _Body extends ConsumerWidget {
  final String hubCommandId;
  const _Body({required this.hubCommandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(spaceForHubProvider(hubCommandId));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(hubsProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Устройства'),
            backgroundColor: AppColors.getBackgroundColor(context),
            elevation: 0,
            pinned: true,
            foregroundColor: AppColors.getTextColor(context),
          ),
          if (space == null)
            const SliverFillRemaining(
              child: Center(child: Text('Space не найден у выбранного хаба')),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SpaceCard(space: space, hubCommandId: hubCommandId),
                const SizedBox(height: 8),
                _UnassignedDevicesSection(hubCommandId: hubCommandId),
                const SizedBox(height: 24),
              ]),
            ),
        ],
      ),
    );
  }
}

class _SpaceCard extends ConsumerWidget {
  final Space space;
  final String hubCommandId;
  const _SpaceCard({required this.space, required this.hubCommandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  space.name,
                  style: AppStyles.headline2(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _showAddRoomDialog(context, ref),
                child: const Text('Добавить комнату'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...space.rooms.map(
            (r) => _RoomCard(space: space, room: r, hubCommandId: hubCommandId),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRoomDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final service = ref.read(roomsServiceProvider);
    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            title: const Text('Новая комната'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Название'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: AppStyles.primaryButtonStyle,
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  await service.createRoom(space.id, name);
                  await ref.refresh(hubsProvider.future);
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
    );
  }
}

class _RoomCard extends ConsumerWidget {
  final Space space;
  final Room room;
  final String hubCommandId;
  const _RoomCard({
    required this.space,
    required this.room,
    required this.hubCommandId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(roomDevicesProvider(room.id));

    return DragTarget<String>(
      onWillAccept: (deviceId) => deviceId != null,
      onAccept: (deviceId) async {
        await ref
            .read(roomsServiceProvider)
            .assignDeviceToRoom(deviceId, room.id);
        // обновляем список: getObjects для комнат, и конкретную комнату для девайсов
        await ref.refresh(hubsProvider.future);
        ref.invalidate(roomDevicesProvider(room.id));
        ref.invalidate(unassignedDevicesProvider(hubCommandId));
      },
      builder: (context, candidateData, rejectedData) {
        final isHover = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.getCardBackgroundColor(context),
            borderRadius: AppStyles.borderRadiusAll(16),
            border: Border.all(
              color:
                  isHover
                      ? AppColors.primaryAccent
                      : AppColors.getBorderGrayColor(context),
              width: isHover ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: AppStyles.borderRadiusAll(16),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 7,
                      child:
                          room.localImagePath == null
                              ? Container(color: Colors.black12)
                              : Image.file(
                                File(room.localImagePath!),
                                fit: BoxFit.cover,
                              ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      right: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.name,
                              style: AppStyles.headline3(
                                context,
                              ).copyWith(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed:
                                () => context.push(
                                  '/edit-room',
                                  extra: {'space': space, 'room': room},
                                ),
                            child: const Text('Изменить'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              devices.when(
                loading: () => const LinearProgressIndicator(),
                error:
                    (e, _) => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Ошибка загрузки устройств: $e'),
                    ),
                data: (list) {
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Нет устройств',
                              style: AppStyles.bodyText2(context),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () => context.push(
                                  '/assign-devices',
                                  extra: {'room': room, 'hubId': hubCommandId},
                                ),
                            child: const Text('Добавить'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        ...list.map(
                          (d) => _DeviceTile(
                            device: d,
                            hubCommandId: hubCommandId,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                () => context.push(
                                  '/assign-devices',
                                  extra: {'room': room, 'hubId': hubCommandId},
                                ),
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить устройство'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final BaseDevice device;
  final String hubCommandId;
  const _DeviceTile({required this.device, required this.hubCommandId});

  String _parsedTypeName(BaseDevice d) {
    if (d is TempHumiditySensorDevice) return 'Датчик температуры и влажности';
    if (d is MotionSensorDevice) return 'Датчик движения';
    if (d is ContactSensorDevice) return 'Датчик открытия';
    if (d is LeakSensorDevice) return 'Датчик протечки';
    if (d is DimmableLightDevice) return 'Свет (диммируемый)';
    if (d is OnOffSwitchDevice) return 'Реле / Выключатель';
    return 'Устройство';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live =
        ref.watch(webSocketNotifierProvider).deviceData[device.friendlyName];
    final current =
        live != null
            ? DeviceParser.parse({...device.rawData, ...live})
            : device;

    String statusText = 'Нет данных';
    Color statusColor = AppColors.getSecondaryTextColor(context);
    bool hasArrow = current is ControllableDevice;

    if (current is OnOffSwitchDevice) {
      statusText = current.isOn ? 'Вкл' : 'Выкл';
      statusColor =
          current.isOn
              ? AppColors.primaryAccent
              : AppColors.getTextColor(context);
    } else if (current is DimmableLightDevice) {
      final p = ((current.brightness / 254) * 100).round();
      statusText = current.isOn ? '$p%' : 'Выкл';
      statusColor =
          current.isOn
              ? AppColors.primaryAccent
              : AppColors.getTextColor(context);
    } else if (current is ContactSensorDevice) {
      statusText = current.isClosed ? 'Закрыто' : 'Открыто';
      statusColor =
          current.isClosed ? AppColors.getTextColor(context) : AppColors.error;
    } else if (current is MotionSensorDevice) {
      statusText = current.hasMotion ? 'Движение' : 'Нет';
      statusColor =
          current.hasMotion ? AppColors.error : AppColors.getTextColor(context);
    } else if (current is TempHumiditySensorDevice) {
      statusText =
          '${current.temperature.toStringAsFixed(1)}°C / ${current.humidity.round()}%';
    } else if (current is LeakSensorDevice) {
      statusText = current.hasLeak ? 'Протечка' : 'Чисто';
      statusColor =
          current.hasLeak ? AppColors.error : AppColors.getTextColor(context);
    }

    final parsedName = _parsedTypeName(current);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: ListTile(
        leading: Icon(
          DeviceUtils.getIconForDevice(current),
          color: statusColor,
        ),
        title: Text(
          parsedName,
          style: AppStyles.bodyText1(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          current.friendlyName,
          style: AppStyles.caption(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: AppStyles.bodyText1(
                  context,
                ).copyWith(color: statusColor, fontWeight: FontWeight.w600),
              ),
              if (hasArrow) const SizedBox(width: 8),
              if (hasArrow)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.getSecondaryTextColor(context),
                ),
            ],
          ),
        ),
        onTap: () {
          if (hasArrow) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => DeviceDetailsScreen(
                      device: current,
                      commandHubId: hubCommandId,
                    ),
              ),
            );
          }
        },
      ),
    );
  }
}

class _UnassignedDevicesSection extends ConsumerWidget {
  final String hubCommandId;
  const _UnassignedDevicesSection({required this.hubCommandId});

  String _parsedTypeName(BaseDevice d) {
    if (d is TempHumiditySensorDevice) return 'Датчик температуры и влажности';
    if (d is MotionSensorDevice) return 'Датчик движения';
    if (d is ContactSensorDevice) return 'Датчик открытия';
    if (d is LeakSensorDevice) return 'Датчик протечки';
    if (d is DimmableLightDevice) return 'Свет (диммируемый)';
    if (d is OnOffSwitchDevice) return 'Реле / Выключатель';
    return 'Устройство';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(unassignedDevicesProvider(hubCommandId));
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackgroundColor(context),
          borderRadius: AppStyles.borderRadiusAll(12),
          border: Border.all(color: AppColors.getBorderGrayColor(context)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primaryAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Нераспределённые устройства',
                      style: AppStyles.headline3(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...list.map((d) {
                final live =
                    ref.watch(webSocketNotifierProvider).deviceData[d
                        .friendlyName];
                final current =
                    live != null
                        ? DeviceParser.parse({...d.rawData, ...live})
                        : d;
                final parsedName = _parsedTypeName(current);

                String statusText = 'Нет данных';
                Color statusColor = AppColors.getSecondaryTextColor(context);
                bool hasArrow = current is ControllableDevice;

                if (current is OnOffSwitchDevice) {
                  statusText = current.isOn ? 'Вкл' : 'Выкл';
                  statusColor =
                      current.isOn
                          ? AppColors.primaryAccent
                          : AppColors.getTextColor(context);
                } else if (current is DimmableLightDevice) {
                  final p = ((current.brightness / 254) * 100).round();
                  statusText = current.isOn ? '$p%' : 'Выкл';
                  statusColor =
                      current.isOn
                          ? AppColors.primaryAccent
                          : AppColors.getTextColor(context);
                } else if (current is TempHumiditySensorDevice) {
                  statusText =
                      '${current.temperature.toStringAsFixed(1)}°C / ${current.humidity.round()}%';
                }

                return LongPressDraggable<String>(
                  data: current.id,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: _dragGhost(context, parsedName),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _tile(
                      context,
                      parsedName,
                      current,
                      statusText,
                      statusColor,
                      hasArrow,
                    ),
                  ),
                  child: _tile(
                    context,
                    parsedName,
                    current,
                    statusText,
                    statusColor,
                    hasArrow,
                    onTap:
                        hasArrow
                            ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => DeviceDetailsScreen(
                                      device: current,
                                      commandHubId: hubCommandId,
                                    ),
                              ),
                            )
                            : null,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragGhost(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: AppStyles.borderRadiusAll(8),
        border: Border.all(color: AppColors.primaryAccent, width: 2),
      ),
      child: Text(
        title,
        style: AppStyles.bodyText1(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String parsedName,
    BaseDevice current,
    String statusText,
    Color statusColor,
    bool hasArrow, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: ListTile(
        leading: Icon(
          DeviceUtils.getIconForDevice(current),
          color: statusColor,
        ),
        title: Text(
          parsedName,
          style: AppStyles.bodyText1(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          current.friendlyName,
          style: AppStyles.caption(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: AppStyles.bodyText1(
                  context,
                ).copyWith(color: statusColor),
              ),
              if (hasArrow) const SizedBox(width: 8),
              if (hasArrow)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.getSecondaryTextColor(context),
                ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
