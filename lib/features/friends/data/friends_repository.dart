import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/friends_models.dart';
import 'friends_api.dart';

final friendsApiProvider = Provider<FriendsApi>((ref) => FriendsApi());

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.watch(friendsApiProvider));
});

class FriendsRepository {
  FriendsRepository(this._api);

  final FriendsApi _api;

  Future<void> requestFriend(String email) => _api.requestFriend(email);

  Future<void> acceptRequest(String requestId) => _api.acceptRequest(requestId);

  Future<void> rejectRequest(String requestId) => _api.rejectRequest(requestId);

  Future<void> removeFriend(String friendId) => _api.removeFriend(friendId);

  Future<List<Friend>> friends() => _api.list();

  Future<List<FriendRequest>> incoming() => _api.incoming();

  Future<List<FriendRequest>> outgoing() => _api.outgoing();

  Future<List<FriendCoordinate>> coordinates() => _api.coordinates();
}
