// lib/widgets/control_device_card.dart
// --- THIS CODE IS NOW CORRECT ---

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/models/device_models.dart';
import 'package:ISS/features/security_control/ws_provider.dart';
import 'package:ISS/utils/device_utils.dart';
import 'package:ISS/utils/device_parser.dart';
import 'package:ISS/features/home/utils/device_keys.dart';

class ControlDeviceCard extends ConsumerWidget {
  final BaseDevice device;
  final String commandHubId;

  const ControlDeviceCard({
    super.key,
    required this.device,
    required this.commandHubId,
  });

  // --- LOGIC IS PRESERVED ---
  String _labelFriendlyOrId(BaseDevice d) {
    final fn = d.friendlyName.trim();
    if (fn.isEmpty) return d.id;
    final lower = fn.toLowerCase();
    if (lower.startsWith('unknown')) return d.id;
    return fn;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final liveMap = ref.watch(webSocketNotifierProvider).deviceData;

    // Device state merging logic is preserved
    Map<String, dynamic>? liveFor(BaseDevice d) {
      final byId = liveMap[d.id];
      if (byId != null) return byId;
      final fn = d.friendlyName.trim();
      if (fn.isEmpty) return null;
      final lower = fn.toLowerCase();
      if (lower.startsWith('unknown')) return null;
      return liveMap[fn];
    }

    final live = liveFor(device);
    final currentDevice =
        live != null
            ? DeviceParser.parse({...device.rawData, ...live})
            : device;
    final commandKey = DeviceKeys.commandKey(currentDevice);
    final bool isOn =
        (currentDevice is ControllableDevice)
            ? (currentDevice as ControllableDevice).isOn
            : false;

    // --- NEW: UI State Variables ---
    final textColor = isOn ? Colors.white : AppColors.getTextColor(context);
    final iconColor = isOn ? Colors.white : AppColors.primaryAccent;
    final mainLabelText = DeviceUtils.getLocalizedDeviceTypeName(
      currentDevice,
      localizations,
    );
    final mainIcon = DeviceUtils.getIconForDevice(currentDevice);

    String subStatusText = isOn ? localizations.on : localizations.off;
    if (currentDevice is DimmableLightDevice) {
      final brightnessPercent =
          ((currentDevice.brightness / 254) * 100).round();
      subStatusText =
          isOn
              ? '${localizations.on} • $brightnessPercent%'
              : localizations.off;
    }

    // Toggle logic is preserved
    void toggle() {
      if (currentDevice is! ControllableDevice) return;
      final newState = !isOn;
      final ws = ref.read(webSocketNotifierProvider.notifier);
      ws.updateDeviceLocalState(commandKey, {
        'state': newState ? 'ON' : 'OFF',
      });
      unawaited(
        ws
            .sendDeviceCommand(commandHubId, commandKey, {
              'state': newState ? 'ON' : 'OFF',
            })
            .catchError((error, stack) {
              debugPrint('[ControlDeviceCard] send command error: $error');
            }),
      );
    }

    // --- NEW: Redesigned Glassmorphic UI ---
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: AppStyles.glassmorphicBoxDecoration(context).copyWith(
            // New "glow" effect when the device is on
            gradient:
                isOn
                    ? LinearGradient(
                      colors: [
                        AppColors.primaryAccent.withOpacity(0.5),
                        AppColors.getGlassFillColor(context),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                    : AppColors.glassGradient(context), // THIS LINE NOW WORKS
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24.0),
              onLongPress:
                  () => _showDeviceControlModal(
                    context,
                    currentDevice,
                    commandHubId,
                    localizations,
                    ref,
                  ),
              onTap: toggle,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(mainIcon, color: iconColor, size: 32),
                    const Spacer(),
                    Text(
                      mainLabelText,
                      style: AppStyles.bodyText1(
                        context,
                      ).copyWith(color: textColor, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _labelFriendlyOrId(currentDevice),
                      style: AppStyles.caption(
                        context,
                      ).copyWith(color: textColor.withOpacity(0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subStatusText,
                      style: AppStyles.bodyText2(
                        context,
                      ).copyWith(color: textColor.withOpacity(0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- NEW: Redesigned Glassmorphic Bottom Sheet ---
void _showDeviceControlModal(
  BuildContext context,
  BaseDevice device,
  String commandHubId,
  AppLocalizations localizations,
  WidgetRef ref,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // Required for glass effect
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext bc) {
      return Consumer(
        builder: (context, widgetRef, child) {
          // All logic for getting live device state is preserved
          final liveMap = widgetRef.watch(webSocketNotifierProvider).deviceData;
          Map<String, dynamic>? liveFor(BaseDevice d) {
            final byId = liveMap[d.id];
            if (byId != null) return byId;
            final fn = d.friendlyName.trim();
            if (fn.isEmpty) return null;
            final lower = fn.toLowerCase();
            if (lower.startsWith('unknown')) return null;
            return liveMap[fn];
          }

          final live = liveFor(device);
          final currentDevice =
              live != null
                  ? DeviceParser.parse({...device.rawData, ...live})
                  : device;
          final commandKey = DeviceKeys.commandKey(currentDevice);
          final bool isOn =
              (currentDevice is ControllableDevice)
                  ? (currentDevice as ControllableDevice).isOn
                  : false;
          String friendlyOrId(BaseDevice d) {
            final fn = d.friendlyName.trim();
            if (fn.isEmpty) return d.id;
            final lower = fn.toLowerCase();
            if (lower.startsWith('unknown')) return d.id;
            return fn;
          }

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: AppStyles.glassmorphicBoxDecoration(
                  context,
                ).copyWith(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 12,
                  left: 20,
                  right: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.getSecondaryTextColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        friendlyOrId(currentDevice),
                        style: AppStyles.headline3(
                          context,
                        ).copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (currentDevice is DimmableLightDevice) ...[
                        Text(
                          localizations.brightness,
                          style: AppStyles.bodyText1(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: currentDevice.brightness.toDouble(),
                                min: 0,
                                max: 254,
                                activeColor: AppColors.primaryAccent,
                                inactiveColor: AppColors.getSecondaryTextColor(
                                  context,
                                ),
                                onChanged:
                                    (value) => widgetRef
                                        .read(
                                          webSocketNotifierProvider.notifier,
                                        )
                                        .updateDeviceLocalState(
                                          commandKey,
                                          {'brightness': value.toInt()},
                                        ),
                                onChangeEnd:
                                    (value) => widgetRef
                                        .read(
                                          webSocketNotifierProvider.notifier,
                                        )
                                        .sendDeviceCommand(
                                          commandHubId,
                                          commandKey,
                                          {"brightness": value.toInt()},
                                        ),
                              ),
                            ),
                            Text(
                              '${(currentDevice.brightness / 254 * 100).round()}%',
                              style: AppStyles.bodyText1(
                                context,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (currentDevice is ControllableDevice)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildOnOffButton(
                                context,
                                ref,
                                currentDevice,
                                commandHubId,
                                true,
                                isOn,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildOnOffButton(
                                context,
                                ref,
                                currentDevice,
                                commandHubId,
                                false,
                                isOn,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// --- Unchanged Helper Widget ---
Widget _buildOnOffButton(
  BuildContext context,
  WidgetRef ref,
  BaseDevice device,
  String commandHubId,
  bool targetStateIsOn,
  bool currentStateIsOn,
) {
  // This widget is fine, but we'll use the newer button style for consistency.
  final localizations = AppLocalizations.of(context);
  final bool isActive = targetStateIsOn == currentStateIsOn;
  final commandKey = DeviceKeys.commandKey(device);
  final style =
      isActive
          ? AppStyles.primaryButtonStyle
          : AppStyles.primaryButtonStyle.copyWith(
            backgroundColor: WidgetStateProperty.all(
              AppColors.getCardBackgroundColor(context),
            ),
            foregroundColor: WidgetStateProperty.all(
              AppColors.getTextColor(context),
            ),
          );

  return ElevatedButton(
    onPressed: () {
      final ws = ref.read(webSocketNotifierProvider.notifier);
      ws.updateDeviceLocalState(commandKey, {
        'state': targetStateIsOn ? 'ON' : 'OFF',
      });
      ws.sendDeviceCommand(commandHubId, commandKey, {
        "state": targetStateIsOn ? "ON" : "OFF",
      });
    },
    style: style,
    child: Text(targetStateIsOn ? localizations.on : localizations.off),
  );
}
