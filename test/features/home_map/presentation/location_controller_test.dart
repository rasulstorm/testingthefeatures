import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ISS/features/friends/data/friends_repository.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';
import 'package:ISS/features/home_map/data/location_service.dart';
import 'package:ISS/features/home_map/data/location_ws_client.dart';
import 'package:ISS/features/home_map/domain/location_models.dart';
import 'package:ISS/features/home_map/presentation/location_controller.dart';

class TestLocationService extends LocationService {
  TestLocationService({
    this.permission = LocationPermissionState.granted,
    this.requestResult,
    this.initialPosition,
  });

  final LocationPermissionState permission;
  LocationPermissionState? requestResult;
  Position? initialPosition;

  final _positionController = StreamController<Position>.broadcast();

  @override
  Future<LocationPermissionState> checkPermission() async => permission;

  @override
  Future<LocationPermissionState> requestPermission() async =>
      requestResult ?? permission;

  @override
  Stream<Position> positionStream({LocationSettings? settings}) =>
      _positionController.stream;

  @override
  Future<Position?> currentPosition() async => initialPosition;

  void emit(Position position) {
    _positionController.add(position);
  }

  void dispose() {
    _positionController.close();
  }
}

class TestFriendsRepository implements FriendsRepository {
  TestFriendsRepository({this.coordinatesResult = const <FriendCoordinate>[]});

  int coordinatesCalls = 0;
  List<FriendCoordinate> coordinatesResult;

  @override
  Future<void> requestFriend(String email) =>
      Future.error(UnimplementedError());

  @override
  Future<void> acceptRequest(String requestId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> rejectRequest(String requestId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> removeFriend(String friendId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Friend>> friends() => Future.value(const <Friend>[]);

  @override
  Future<List<FriendRequest>> incoming() =>
      Future.value(const <FriendRequest>[]);

  @override
  Future<List<FriendRequest>> outgoing() =>
      Future.value(const <FriendRequest>[]);

  @override
  Future<List<FriendCoordinate>> coordinates() async {
    coordinatesCalls += 1;
    return coordinatesResult;
  }
}

class TestLocationWsClient implements LocationWsClient {
  TestLocationWsClient({this.connectSucceeds = true});

  final bool connectSucceeds;
  bool _connected = false;
  int connectCalls = 0;
  int disconnectCalls = 0;
  final List<(double lat, double lon)> sentLocations = [];

  final _statusController = StreamController<bool>.broadcast();
  final _friendsController =
      StreamController<List<FriendCoordinate>>.broadcast();

  @override
  bool get isConnected => _connected;

  @override
  Stream<List<FriendCoordinate>> get friendsStream => _friendsController.stream;

  @override
  Stream<bool> get statusStream => _statusController.stream;

  @override
  Future<void> connect() async {
    connectCalls += 1;
    _connected = connectSucceeds;
    _statusController.add(_connected);
  }

  @override
  void disconnect() {
    disconnectCalls += 1;
    if (_connected) {
      _connected = false;
      _statusController.add(false);
    }
  }

  @override
  void dispose() {
    _statusController.close();
    _friendsController.close();
  }

  @override
  void updateSelfLocation(double latitude, double longitude) {
    sentLocations.add((latitude, longitude));
  }

  // Helpers for tests
  void emitFriends(List<FriendCoordinate> friends) {
    _friendsController.add(friends);
  }

  void emitStatus(bool status) {
    _connected = status;
    _statusController.add(status);
  }
}

Position testPosition(double latitude, double longitude) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2024),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 0,
    floor: null,
    isMocked: false,
  );
}

void main() {
  late TestLocationService locationService;
  late TestFriendsRepository friendsRepository;
  late TestLocationWsClient wsClient;
  late DateTime currentTime;

  DateTime now() => currentTime;

  setUp(() {
    currentTime = DateTime(2024, 1, 1, 12, 0, 0);
    locationService = TestLocationService(
      initialPosition: testPosition(43.25, 76.95),
    );
    friendsRepository = TestFriendsRepository();
    wsClient = TestLocationWsClient();
  });

  tearDown(() {
    locationService.dispose();
    wsClient.dispose();
  });

  Future<MapLocationController> createController() async {
    final controller = MapLocationController(
      locationService,
      friendsRepository,
      wsClient,
      now: now,
    );
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
    return controller;
  }

  test('sends initial location immediately after init', () async {
    final controller = await createController();

    expect(wsClient.sentLocations, isNotEmpty);
    expect(wsClient.sentLocations.first, (43.25, 76.95));
    expect(controller.state.self?.latitude, 43.25);
    controller.dispose();
  });

  test('does not send when movement <25m and <30s', () async {
    final controller = await createController();
    expect(wsClient.sentLocations.length, 1);

    currentTime = currentTime.add(const Duration(seconds: 10));
    locationService.emit(testPosition(43.25005, 76.95005));
    await Future.delayed(Duration.zero);

    expect(wsClient.sentLocations.length, 1);
    controller.dispose();
  });

  test('sends when 30s elapsed even without movement', () async {
    final controller = await createController();
    wsClient.sentLocations.clear();

    currentTime = currentTime.add(const Duration(seconds: 31));
    locationService.emit(testPosition(43.25, 76.95));
    await Future.delayed(Duration.zero);

    expect(wsClient.sentLocations.length, 1);
    controller.dispose();
  });

  test('fallback triggers coordinates fetch when socket unavailable', () async {
    wsClient = TestLocationWsClient(connectSucceeds: false);
    final controller = await createController();

    await Future.delayed(Duration.zero);
    expect(friendsRepository.coordinatesCalls, isPositive);
    expect(controller.state.usingFallback, isTrue);
    controller.dispose();
  });

  test('syncNow forces send on resume', () async {
    final controller = await createController();
    wsClient.sentLocations.clear();

    currentTime = currentTime.add(const Duration(seconds: 5));
    locationService.initialPosition = testPosition(43.2503, 76.9503);
    await controller.syncNow();

    expect(wsClient.sentLocations.length, 1);
    expect(wsClient.sentLocations.first.$1, closeTo(43.2503, 1e-6));
    controller.dispose();
  });
}
