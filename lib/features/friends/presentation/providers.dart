// lib/features/friends/presentation/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/friends_models.dart';
import '../../friends/data/friends_repository.dart';
import 'package:ISS/main.dart' show authServiceProvider;

/// Список друзей
final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.friends();
});

/// Входящие заявки
final incomingRequestsProvider = FutureProvider<List<FriendRequest>>((
  ref,
) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.incoming();
});

/// Исходящие заявки
final outgoingRequestsProvider = FutureProvider<List<FriendRequest>>((
  ref,
) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.outgoing();
});

/// Координаты друзей
final friendsCoordinatesProvider = FutureProvider<List<FriendCoordinate>>((
  ref,
) async {
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.coordinates();
});

final currentUserEmailProvider = FutureProvider<String?>((ref) async {
  final auth = ref.watch(authServiceProvider);
  return auth.getCurrentUserEmail();
});

final friendsActionsProvider = Provider<FriendsActions>((ref) {
  return FriendsActions(ref);
});

class FriendsActions {
  FriendsActions(this._ref);

  final Ref _ref;

  FriendsRepository get _repo => _ref.read(friendsRepositoryProvider);

  Future<void> requestFriend(String email) async {
    await _repo.requestFriend(email);
    _ref.invalidate(outgoingRequestsProvider);
  }

  Future<void> acceptRequest(String requestId) async {
    await _repo.acceptRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
    _ref.invalidate(friendsListProvider);
  }

  Future<void> rejectRequest(String requestId) async {
    await _repo.rejectRequest(requestId);
    _ref.invalidate(incomingRequestsProvider);
  }

  Future<void> removeFriend(String friendId) async {
    await _repo.removeFriend(friendId);
    _ref.invalidate(friendsListProvider);
    _ref.invalidate(friendsCoordinatesProvider);
  }

  Future<List<FriendCoordinate>> refreshCoordinates() async {
    final list = await _repo.coordinates();
    _ref.invalidate(friendsCoordinatesProvider);
    return list;
  }
}
