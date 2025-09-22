// lib/features/home/widgets/hub_sliver_app_bar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/models/hub_models.dart';
import 'package:ISS/services/picovoice_service.dart';
import 'package:ISS/features/hub_photo/hub_photo_controller.dart';

class HubSliverAppBar extends ConsumerStatefulWidget {
  final HubObject currentHub;
  final List<HubObject> hubs;
  final Animation<double> micAnimation;

  final VoidCallback onTitleTap;
  final VoidCallback onUploadPhoto;
  final VoidCallback onOpenPins;
  final VoidCallback onStartPairing;
  final VoidCallback onDetach;
  final VoidCallback onRename;

  const HubSliverAppBar({
    super.key,
    required this.currentHub,
    required this.hubs,
    required this.micAnimation,
    required this.onTitleTap,
    required this.onUploadPhoto,
    required this.onOpenPins,
    required this.onStartPairing,
    required this.onDetach,
    required this.onRename,
  });

  @override
  ConsumerState<HubSliverAppBar> createState() => _HubSliverAppBarState();
}

class _HubSliverAppBarState extends ConsumerState<HubSliverAppBar> {
  @override
  Widget build(BuildContext context) {
    final hubPhotoState = ref.watch(hubPhotoControllerProvider);
    final backgroundUrl = hubPhotoState.url;
    final picovoiceState = ref.watch(picovoiceProvider);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.getBackgroundColor(context).withOpacity(0.8),
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: InkWell(
              onTap: widget.onTitleTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.currentHub.facilityName,
                      style: AppStyles.headline3(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 20,
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backgroundUrl != null)
                  Image.network(
                    backgroundUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  )
                else
                  Image.asset(
                    'assets/images/home_background.jpg',
                    fit: BoxFit.cover,
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        AppColors.getBackgroundColor(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: ScaleTransition(
            scale: widget.micAnimation,
            child: Icon(
              picovoiceState == PicovoiceState.stopped
                  ? Icons.mic_off_outlined
                  : Icons.mic_outlined,
              color:
                  picovoiceState == PicovoiceState.listeningForCommand
                      ? AppColors.primaryAccent
                      : AppColors.getTextColor(context),
            ),
          ),
          onPressed:
              () => ref.read(picovoiceProvider.notifier).toggleListening(),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'upload_photo') widget.onUploadPhoto();
            if (value == 'pins') widget.onOpenPins();
            if (value == 'pairing') widget.onStartPairing();
            if (value == 'detach') widget.onDetach();
            if (value == 'rename') widget.onRename();
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'upload_photo',
                  child: ListTile(
                    leading: Icon(Icons.camera_alt_outlined),
                    title: Text('Сменить обложку'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pins',
                  child: ListTile(
                    leading: Icon(Icons.admin_panel_settings_outlined),
                    title: Text('PIN-коды'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pairing',
                  child: ListTile(
                    leading: Icon(Icons.leak_add_outlined),
                    title: Text('Поиск устройств'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Переименовать'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'detach',
                  child: ListTile(
                    leading: Icon(Icons.link_off, color: AppColors.error),
                    title: Text(
                      'Отвязать хаб',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
          icon: Icon(Icons.more_vert, color: AppColors.getTextColor(context)),
        ),
      ],
    );
  }
}
