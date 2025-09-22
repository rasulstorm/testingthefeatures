import 'package:equatable/equatable.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';

enum LocationPermissionState {
  unknown,
  requesting,
  granted,
  denied,
  permanentlyDenied,
}

class GeoPoint extends Equatable {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  @override
  List<Object> get props => [latitude, longitude];
}

class MapLocationState extends Equatable {
  const MapLocationState({
    required this.permission,
    required this.isLoading,
    required this.socketConnected,
    required this.usingFallback,
    required this.friends,
    this.self,
    this.errorKey,
    this.selectedFriendId,
    this.lastUpdated,
  });

  factory MapLocationState.initial() => const MapLocationState(
    permission: LocationPermissionState.unknown,
    isLoading: true,
    socketConnected: false,
    usingFallback: false,
    friends: <FriendCoordinate>[],
  );

  final LocationPermissionState permission;
  final bool isLoading;
  final bool socketConnected;
  final bool usingFallback;
  final List<FriendCoordinate> friends;
  final GeoPoint? self;
  final String? selectedFriendId;
  final String? errorKey;
  final DateTime? lastUpdated;

  MapLocationState copyWith({
    LocationPermissionState? permission,
    bool? isLoading,
    bool? socketConnected,
    bool? usingFallback,
    List<FriendCoordinate>? friends,
    GeoPoint? self,
    Object? selectedFriendId = _sentinel,
    Object? errorKey = _sentinel,
    DateTime? lastUpdated,
  }) {
    return MapLocationState(
      permission: permission ?? this.permission,
      isLoading: isLoading ?? this.isLoading,
      socketConnected: socketConnected ?? this.socketConnected,
      usingFallback: usingFallback ?? this.usingFallback,
      friends: friends ?? this.friends,
      self: self ?? this.self,
      selectedFriendId:
          selectedFriendId == _sentinel
              ? this.selectedFriendId
              : selectedFriendId as String?,
      errorKey: errorKey == _sentinel ? this.errorKey : errorKey as String?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    permission,
    isLoading,
    socketConnected,
    usingFallback,
    friends,
    self,
    selectedFriendId,
    errorKey,
    lastUpdated,
  ];
}

const Object _sentinel = Object();
