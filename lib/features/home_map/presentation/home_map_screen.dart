import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';

import '../domain/location_models.dart';
import 'location_controller.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  ProviderSubscription<MapLocationState>? _subscription;
  late final DraggableScrollableController _sheetController;
  bool _hasFitInitial = false;
  bool _showOffline = false;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    WidgetsBinding.instance.addObserver(this);
    _subscription = ref.listenManual<MapLocationState>(
      mapLocationControllerProvider,
      (previous, next) {
        if (!_hasFitInitial && (next.self != null || next.friends.isNotEmpty)) {
          _hasFitInitial = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitToBounds(next);
          });
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.close();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final controller = ref.read(mapLocationControllerProvider.notifier);
      unawaited(controller.syncNow());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(mapLocationControllerProvider);
    final controller = ref.read(mapLocationControllerProvider.notifier);
    final locationService = ref.read(locationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.homeMapTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: loc.homeMapFriendsButton,
            onPressed: () => context.push('/friends'),
          ),
        ],
      ),
      body:
          state.permission == LocationPermissionState.granted
              ? _buildMapContent(context, loc, state, controller)
              : _PermissionView(
                permissionState: state.permission,
                isLoading: state.isLoading,
                onRequestPermission: () => controller.requestPermission(),
                onOpenSettings: () async {
                  final opened = await locationService.openAppSettings();
                  if (!opened) {
                    await locationService.openLocationSettings();
                  }
                },
                messageKey: state.errorKey,
              ),
    );
  }

  Widget _buildMapContent(
    BuildContext context,
    AppLocalizations loc,
    MapLocationState state,
    MapLocationController controller,
  ) {
    final theme = Theme.of(context);
    final center = _resolveCenter(state) ?? const LatLng(43.238949, 76.889709);
    final markers = _buildFriendMarkers(context, state, controller);
    final selfMarker = _buildSelfMarker(context, state.self);
    FriendCoordinate? selectedFriend;
    if (state.selectedFriendId != null) {
      for (final friend in state.friends) {
        if (friend.userId == state.selectedFriendId) {
          selectedFriend = friend;
          break;
        }
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            maxZoom: 18,
            minZoom: 3,
            // ignore: unnecessary_underscores
            onTap: (_, __) {
              controller.selectFriend(null);
              _collapseFriendsSheet();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.isscontrol.app',
            ),
            if (markers.isNotEmpty)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  markers: markers,
                  maxClusterRadius: 60,
                  size: const Size(52, 52),
                  alignment: Alignment.center,
                  builder:
                      (context, clusterMarkers) =>
                          _ClusterBadge(count: clusterMarkers.length),
                ),
              ),
            if (selfMarker != null) MarkerLayer(markers: [selfMarker]),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: 16,
          child: _MapControls(
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
            onFit: () => _fitToBounds(state),
            onLocate: () => _recenterOnSelf(state, context),
          ),
        ),
        _BottomSheetFriends(
          showOffline: _showOffline,
          onToggleOffline: (value) {
            setState(() => _showOffline = value);
          },
          state: state,
          loc: loc,
          theme: theme,
          sheetController: _sheetController,
          selectedFriend: selectedFriend,
          onCloseSelected: () {
            controller.selectFriend(null);
            _collapseFriendsSheet();
          },
          onTapFriend: (friend) {
            controller.selectFriend(friend.userId);
            _moveToFriend(friend);
            _expandFriendsSheet();
          },
          onInvite: () => context.push('/friends'),
          onRetry: () => controller.refreshFriendsFallback(),
          onRouteFriend: (friend) => _openRoute(friend, loc),
          onCallFriend: (friend) => _showStub(context, loc),
          onMessageFriend: (friend) => _showStub(context, loc),
        ),
      ],
    );
  }

  Future<void> _openRoute(FriendCoordinate friend, AppLocalizations loc) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${friend.latitude},${friend.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showStub(BuildContext context, AppLocalizations loc) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.homeMapActionStub)));
  }

  List<Marker> _buildFriendMarkers(
    BuildContext context,
    MapLocationState state,
    MapLocationController controller,
  ) {
    final theme = Theme.of(context);
    final filtered =
        state.friends.where((friend) {
          if (_showOffline) return true;
          return friend.isOnline;
        }).toList();

    return filtered
        .map(
          (friend) => Marker(
            width: 58,
            height: 58,
            point: LatLng(friend.latitude, friend.longitude),
            child: GestureDetector(
              onTap: () {
                controller.selectFriend(friend.userId);
                _moveToFriend(friend);
              },
              child: _FriendMarker(
                friend: friend,
                selected: state.selectedFriendId == friend.userId,
                theme: theme,
              ),
            ),
          ),
        )
        .toList();
  }

  Marker? _buildSelfMarker(BuildContext context, GeoPoint? point) {
    if (point == null) return null;
    final theme = Theme.of(context);
    return Marker(
      width: 62,
      height: 62,
      point: LatLng(point.latitude, point.longitude),
      child: _SelfMarker(theme: theme),
    );
  }

  LatLng? _resolveCenter(MapLocationState state) {
    if (state.selectedFriendId != null) {
      final friend = state.friends.firstWhere(
        (element) => element.userId == state.selectedFriendId,
        orElse:
            () =>
                state.friends.isNotEmpty
                    ? state.friends.first
                    : FriendCoordinate(
                      userId: '',
                      latitude: state.self?.latitude ?? 0,
                      longitude: state.self?.longitude ?? 0,
                    ),
      );
      return LatLng(friend.latitude, friend.longitude);
    }
    if (state.self != null) {
      return LatLng(state.self!.latitude, state.self!.longitude);
    }
    if (state.friends.isNotEmpty) {
      final f = state.friends.first;
      return LatLng(f.latitude, f.longitude);
    }
    return null;
  }

  void _moveToFriend(FriendCoordinate friend) {
    final target = LatLng(friend.latitude, friend.longitude);
    _mapController.move(target, math.max(_mapController.camera.zoom, 15));
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final targetZoom = (camera.zoom + delta).clamp(3.0, 18.0);
    _mapController.move(camera.center, targetZoom);
  }

  void _recenterOnSelf(MapLocationState state, BuildContext context) {
    final self = state.self;
    if (self == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).homeMapNoSelf)),
      );
      return;
    }
    final target = LatLng(self.latitude, self.longitude);
    _mapController.move(target, math.max(_mapController.camera.zoom, 15));
  }

  void _expandFriendsSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.55,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _collapseFriendsSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.25,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _fitToBounds(MapLocationState state) {
    final points = <LatLng>[];
    if (state.self != null) {
      points.add(LatLng(state.self!.latitude, state.self!.longitude));
    }
    points.addAll(state.friends.map((f) => LatLng(f.latitude, f.longitude)));
    if (points.length < 2) {
      if (points.isNotEmpty) {
        _mapController.move(points.first, 14);
      }
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
      );
    } catch (_) {
      // ignore fit errors when map not ready
    }
  }
}

class _ClusterBadge extends StatelessWidget {
  const _ClusterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SelfMarker extends StatelessWidget {
  const _SelfMarker({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: const Icon(Icons.my_location, color: Colors.white),
    );
  }
}

class _FriendMarker extends StatelessWidget {
  const _FriendMarker({
    required this.friend,
    required this.selected,
    required this.theme,
  });

  final FriendCoordinate friend;
  final bool selected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        selected
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary.withValues(alpha: 0.9);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.26),
            blurRadius: selected ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        friend.initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _BottomSheetFriends extends StatelessWidget {
  const _BottomSheetFriends({
    required this.showOffline,
    required this.onToggleOffline,
    required this.state,
    required this.loc,
    required this.theme,
    required this.onTapFriend,
    required this.onInvite,
    required this.onRetry,
    required this.sheetController,
    required this.selectedFriend,
    required this.onCloseSelected,
    required this.onRouteFriend,
    required this.onCallFriend,
    required this.onMessageFriend,
  });

  final bool showOffline;
  final ValueChanged<bool> onToggleOffline;
  final MapLocationState state;
  final AppLocalizations loc;
  final ThemeData theme;
  final void Function(FriendCoordinate friend) onTapFriend;
  final VoidCallback onInvite;
  final VoidCallback onRetry;
  final DraggableScrollableController sheetController;
  final FriendCoordinate? selectedFriend;
  final VoidCallback onCloseSelected;
  final void Function(FriendCoordinate friend) onRouteFriend;
  final void Function(FriendCoordinate friend) onCallFriend;
  final void Function(FriendCoordinate friend) onMessageFriend;

  @override
  Widget build(BuildContext context) {
    final items =
        state.friends.where((f) => showOffline || f.isOnline).toList()
          ..sort((a, b) {
            if (a.isOnline == b.isOnline) {
              return (b.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    a.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0),
                  );
            }
            return a.isOnline ? -1 : 1;
          });

    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: 0.25,
      minChildSize: 0.22,
      maxChildSize: 0.78,
      snap: true,
      builder: (context, scrollController) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.94),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 18,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.homeMapFriendsOnline(
                                          state.friends
                                              .where((e) => e.isOnline)
                                              .length,
                                        ),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      if (state.usingFallback)
                                        Text(
                                          loc.homeMapFallback,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.secondary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      loc.homeMapShowOffline,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: showOffline,
                                      onChanged: onToggleOffline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.errorKey != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _describeLocationError(loc, state.errorKey!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: onRetry,
                                child: Text(loc.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (selectedFriend != null)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SelectedFriendCard(
                            friend: selectedFriend!,
                            loc: loc,
                            theme: theme,
                            onClose: onCloseSelected,
                            onRoute: () => onRouteFriend(selectedFriend!),
                            onCall: () => onCallFriend(selectedFriend!),
                            onMessage: () => onMessageFriend(selectedFriend!),
                          ),
                        ),
                      ),
                    if (state.isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _SkeletonList(),
                      )
                    else if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          onInvite: onInvite,
                          loc: loc,
                          theme: theme,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final friend = items[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == items.length - 1 ? 0 : 12,
                              ),
                              child: _FriendTile(
                                friend: friend,
                                theme: theme,
                                loc: loc,
                                onTap: () => onTapFriend(friend),
                                selected:
                                    state.selectedFriendId == friend.userId,
                                selfPoint: state.self,
                              ),
                            );
                          }, childCount: items.length),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          height: 72,
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.theme,
    required this.loc,
    required this.onTap,
    required this.selected,
    required this.selfPoint,
  });

  final FriendCoordinate friend;
  final ThemeData theme;
  final AppLocalizations loc;
  final VoidCallback onTap;
  final bool selected;
  final GeoPoint? selfPoint;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _formatDistance(selfPoint, friend, loc);
    final updatedLabel = _formatUpdated(friend, loc);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:
                selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.16)
                    : theme.cardColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.18,
                ),
                child: Text(
                  friend.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusDot(active: friend.isOnline),
                        const SizedBox(width: 6),
                        Text(
                          friend.isOnline
                              ? loc.homeMapStatusOnline
                              : loc.homeMapStatusOffline,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (distanceLabel != null)
                      Text(distanceLabel, style: theme.textTheme.bodySmall),
                    if (updatedLabel != null)
                      Text(updatedLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatDistance(
    GeoPoint? self,
    FriendCoordinate friend,
    AppLocalizations loc,
  ) {
    if (self == null) return null;
    final distance = Geolocator.distanceBetween(
      self.latitude,
      self.longitude,
      friend.latitude,
      friend.longitude,
    );
    if (distance.isNaN) return null;
    if (distance >= 1000) {
      final km = distance / 1000;
      return loc.homeMapDistanceKm(km.toStringAsFixed(1));
    }
    return loc.homeMapDistanceM(distance.round());
  }

  String? _formatUpdated(FriendCoordinate friend, AppLocalizations loc) {
    final ts = friend.lastUpdated;
    if (ts == null) return null;
    return _formatRelative(ts, loc);
  }
}

String _formatRelative(DateTime ts, AppLocalizations loc) {
  final diff = DateTime.now().difference(ts);
  if (diff.inMinutes < 1) return loc.homeMapUpdatedNow;
  if (diff.inMinutes < 60) return loc.homeMapUpdatedMinutes(diff.inMinutes);
  if (diff.inHours < 24) return loc.homeMapUpdatedHours(diff.inHours);
  return loc.homeMapUpdatedDays(diff.inDays);
}

class _SelectedFriendCard extends StatelessWidget {
  const _SelectedFriendCard({
    required this.friend,
    required this.loc,
    required this.theme,
    required this.onClose,
    required this.onRoute,
    required this.onCall,
    required this.onMessage,
  });

  final FriendCoordinate friend;
  final AppLocalizations loc;
  final ThemeData theme;
  final VoidCallback onClose;
  final VoidCallback onRoute;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.18,
                ),
                child: Text(
                  friend.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StatusDot(active: friend.isOnline),
                        const SizedBox(width: 6),
                        Text(
                          friend.isOnline
                              ? loc.homeMapStatusOnline
                              : loc.homeMapStatusOffline,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (friend.lastUpdated != null)
                      Text(
                        _formatRelative(friend.lastUpdated!, loc),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.alt_route_rounded,
                  label: loc.homeMapActionRoute,
                  onTap: onRoute,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: loc.homeMapActionMessage,
                  onTap: onMessage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_outlined,
                  label: loc.homeMapActionCall,
                  onTap: onCall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onLocate,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MapControlButton(
          icon: Icons.add,
          tooltip: loc.homeMapZoomIn,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: Icons.remove,
          tooltip: loc.homeMapZoomOut,
          onTap: onZoomOut,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: Icons.my_location,
          tooltip: loc.homeMapLocate,
          onTap: onLocate,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: Icons.center_focus_strong,
          tooltip: loc.homeMapFit,
          onTap: onFit,
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 6,
        color: theme.cardColor.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, textAlign: TextAlign.center),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? AppColors.success : AppColors.lightGreyDark,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onInvite,
    required this.loc,
    required this.theme,
  });

  final VoidCallback onInvite;
  final AppLocalizations loc;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.homeMapNoFriendsTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onInvite,
              child: Text(loc.homeMapInviteButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({
    required this.permissionState,
    required this.isLoading,
    required this.onRequestPermission,
    required this.onOpenSettings,
    this.messageKey,
  });

  final LocationPermissionState permissionState;
  final bool isLoading;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onOpenSettings;
  final String? messageKey;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final bool permanentlyDenied =
        permissionState == LocationPermissionState.permanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                loc.homeMapPermissionTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.homeMapPermissionDescription,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (messageKey != null) ...[
                const SizedBox(height: 8),
                Text(
                  _describeLocationError(loc, messageKey!),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (permanentlyDenied)
                ElevatedButton(
                  onPressed: () {
                    onOpenSettings();
                  },
                  child: Text(loc.homeMapOpenSettings),
                )
              else
                ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            onRequestPermission();
                          },
                  child: Text(loc.generalAllow),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _describeLocationError(AppLocalizations loc, String key) {
  switch (key) {
    case 'friends_error_generic':
      return loc.homeMapErrorGeneric;
    case 'friends_error_unauthorized':
      return loc.homeMapErrorUnauthorized;
    case 'friends_error_forbidden':
      return loc.homeMapErrorForbidden;
    case 'friends_error_not_found':
      return loc.homeMapErrorNotFound;
    case 'friends_error_conflict':
      return loc.homeMapErrorConflict;
    case 'location_error_permission':
      return loc.homeMapErrorPermission;
    default:
      return key;
  }
}
