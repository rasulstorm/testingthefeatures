import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;

import 'package:ISS/features/friends/data/friends_repository.dart';
import 'package:ISS/features/friends/data/friends_api.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';
import 'package:ISS/main.dart';

import '../data/location_service.dart';
import '../data/location_ws_client.dart';
import '../domain/location_models.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationWsClientProvider = Provider.autoDispose<LocationWsClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  final client = LocationWsClient(authService: authService);
  ref.onDispose(client.dispose);
  return client;
});

final mapLocationControllerProvider =
    StateNotifierProvider.autoDispose<MapLocationController, MapLocationState>((
      ref,
    ) {
      final controller = MapLocationController(
        ref.watch(locationServiceProvider),
        ref.watch(friendsRepositoryProvider),
        ref.watch(locationWsClientProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

class MapLocationController extends StateNotifier<MapLocationState> {
  MapLocationController(
    this._locationService,
    this._friendsRepository,
    this._wsClient, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(MapLocationState.initial()) {
    _init();
  }

  final LocationService _locationService;
  final FriendsRepository _friendsRepository;
  final LocationWsClient _wsClient;
  final DateTime Function() _now;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<bool>? _statusSub;
  StreamSubscription<List<FriendCoordinate>>? _friendsSub;
  Timer? _fallbackTimer;

  GeoPoint? _lastSentPoint;
  DateTime? _lastSentAt;
  final latlng.Distance _distance = const latlng.Distance();

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    state = state.copyWith(
      isLoading: true,
      permission: LocationPermissionState.requesting,
      errorKey: null,
    );

    var permission = await _locationService.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermissionState.denied ||
        permission == LocationPermissionState.unknown) {
      permission = await _locationService.requestPermission();
      if (!mounted) return;
    }

    state = state.copyWith(permission: permission);

    if (permission != LocationPermissionState.granted) {
      state = state.copyWith(
        isLoading: false,
        errorKey: 'location_error_permission',
      );
      return;
    }

    await _startListeningPosition();
    await _connectWebSocket();

    if (!mounted) return;
    state = state.copyWith(isLoading: false, errorKey: null);
  }

  Future<void> requestPermission() async {
    final permission = await _locationService.requestPermission();
    if (!mounted) return;
    state = state.copyWith(permission: permission);
    if (permission == LocationPermissionState.granted) {
      await _startListeningPosition();
      await _connectWebSocket();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorKey: null);
    } else if (permission == LocationPermissionState.permanentlyDenied) {
      state = state.copyWith(errorKey: 'location_error_permission');
    }
  }

  Future<void> _startListeningPosition() async {
    final current = await _locationService.currentPosition();
    if (!mounted) return;
    if (current != null) {
      _processPosition(current, forceSend: true);
    }

    _positionSub?.cancel();
    _positionSub = _locationService.positionStream().listen(
      (position) => _processPosition(position, forceSend: false),
      onError: (error, stack) {
        debugPrint('[MapLocationController] position stream error: $error');
      },
    );
  }

  Future<void> _connectWebSocket() async {
    _statusSub?.cancel();
    _statusSub = _wsClient.statusStream.listen((connected) {
      if (!mounted) return;
      state = state.copyWith(socketConnected: connected);
      if (connected) {
        _stopFallback();
      } else {
        _startFallback();
      }
    });

    _friendsSub?.cancel();
    _friendsSub = _wsClient.friendsStream.listen((friends) {
      if (!mounted) return;
      state = state.copyWith(
        friends: friends,
        usingFallback: false,
        errorKey: null,
        lastUpdated: _now(),
      );
    });

    await _wsClient.connect();
    if (!_wsClient.isConnected) {
      _startFallback();
    }
  }

  void selectFriend(String? friendId) {
    state = state.copyWith(selectedFriendId: friendId);
  }

  Future<void> refreshFriendsFallback() async {
    try {
      final data = await _friendsRepository.coordinates();
      if (!mounted) return;
      state = state.copyWith(
        friends: data,
        usingFallback: true,
        errorKey: null,
        lastUpdated: _now(),
      );
    } on FriendsApiException catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorKey: e.message);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(errorKey: 'friends_error_generic');
    }
  }

  void _startFallback() {
    if (_fallbackTimer == null) {
      _fallbackTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => refreshFriendsFallback(),
      );
      unawaited(refreshFriendsFallback());
    }
  }

  void _stopFallback() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _positionSub?.cancel();
    _statusSub?.cancel();
    _friendsSub?.cancel();
    _wsClient.disconnect();
    super.dispose();
  }

  Future<void> syncNow() async {
    final position = await _locationService.currentPosition();
    if (!mounted) return;
    if (position != null) {
      _processPosition(position, forceSend: true);
    }
  }

  void _processPosition(Position position, {required bool forceSend}) {
    if (!mounted) return;
    final point = GeoPoint(position.latitude, position.longitude);
    state = state.copyWith(self: point, lastUpdated: _now());

    final shouldSend = forceSend || _shouldSendLocation(point);
    if (!shouldSend) return;

    _wsClient.updateSelfLocation(position.latitude, position.longitude);
    _lastSentPoint = point;
    _lastSentAt = _now();
  }

  bool _shouldSendLocation(GeoPoint point) {
    final lastPoint = _lastSentPoint;
    final lastTime = _lastSentAt;

    if (lastPoint == null || lastTime == null) {
      return true;
    }

    final distance = _distance.as(
      latlng.LengthUnit.Meter,
      latlng.LatLng(lastPoint.latitude, lastPoint.longitude),
      latlng.LatLng(point.latitude, point.longitude),
    );

    if (distance >= 25) {
      return true;
    }

    final elapsed = _now().difference(lastTime);
    if (elapsed >= const Duration(seconds: 30)) {
      return true;
    }

    return false;
  }
}
