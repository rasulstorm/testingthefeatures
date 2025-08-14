// lib/features/rooms/room_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/rooms/rooms_providers.dart';
import 'package:ISS/models/space_model.dart' as server_models;
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/utils/device_utils.dart';

class RoomDetailsScreen extends ConsumerWidget {
  final server_models.Room room;
  const RoomDetailsScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesInRoomAsync = ref.watch(roomDevicesProvider(room.id));
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.getCardBackgroundColor(context),
            foregroundColor: AppColors.getTextColor(context),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              centerTitle: false,
              title: Text(
                room.name,
                style: AppStyles.headline4(context).copyWith(
                  color: AppColors.textColorDark,
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.7)),
                  ],
                ),
              ),
              background: Container(
                color: AppColors.getCardBackgroundColor(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                localizations.devicesInRoom,
                style: AppStyles.headline3(context),
              ),
            ),
          ),
          devicesInRoomAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (err, stack) => SliverFillRemaining(
                  child: Center(child: Text("Error: $err")),
                ),
            data: (devicesInRoom) {
              if (devicesInRoom.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      localizations.noDevicesInRoom,
                      style: AppStyles.bodyText2(context),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _DeviceTile(device: devicesInRoom[index]),
                    childCount: devicesInRoom.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final BaseDevice device;
  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      child: ListTile(
        leading: Icon(
          DeviceUtils.getIconForDevice(device),
          color: AppColors.primaryAccent,
        ),
        title: Text(device.friendlyName, style: AppStyles.bodyText1(context)),
      ),
    );
  }
}
