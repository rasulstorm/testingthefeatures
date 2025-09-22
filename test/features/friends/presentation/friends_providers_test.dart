import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ISS/features/friends/data/friends_repository.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';
import 'package:ISS/features/friends/presentation/providers.dart';

class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository({
    required this.friendsData,
    required this.incomingData,
    required this.outgoingData,
    required this.coordinatesData,
  });

  final List<Friend> friendsData;
  final List<FriendRequest> incomingData;
  final List<FriendRequest> outgoingData;
  final List<FriendCoordinate> coordinatesData;

  final List<String> sentRequests = [];
  final List<String> acceptedRequests = [];
  final List<String> rejectedRequests = [];
  final List<String> removedFriends = [];

  @override
  Future<void> requestFriend(String email) async {
    sentRequests.add(email);
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    acceptedRequests.add(requestId);
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    rejectedRequests.add(requestId);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    removedFriends.add(friendId);
  }

  @override
  Future<List<Friend>> friends() async => friendsData;

  @override
  Future<List<FriendRequest>> incoming() async => incomingData;

  @override
  Future<List<FriendRequest>> outgoing() async => outgoingData;

  @override
  Future<List<FriendCoordinate>> coordinates() async => coordinatesData;
}

void main() {
  late FakeFriendsRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeFriendsRepository(
      friendsData: [Friend(id: '1', email: 'alice@example.com')],
      incomingData: [
        FriendRequest(
          id: 'req-in-1',
          email: 'incoming@example.com',
          status: FriendRequestStatus.pending,
          createdAt: DateTime.utc(2024, 01, 01),
        ),
      ],
      outgoingData: [
        FriendRequest(
          id: 'req-out-1',
          email: 'outgoing@example.com',
          status: FriendRequestStatus.pending,
          createdAt: DateTime.utc(2024, 01, 02),
        ),
      ],
      coordinatesData: [
        FriendCoordinate(userId: 'coord-1', latitude: 43.25, longitude: 76.95),
      ],
    );

    container = ProviderContainer(
      overrides: [friendsRepositoryProvider.overrideWithValue(fakeRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('friendsListProvider returns friends from repository', () async {
    final result = await container.read(friendsListProvider.future);
    expect(result, fakeRepository.friendsData);
  });

  test('incomingRequestsProvider returns incoming requests', () async {
    final result = await container.read(incomingRequestsProvider.future);
    expect(result, fakeRepository.incomingData);
  });

  test('outgoingRequestsProvider returns outgoing requests', () async {
    final result = await container.read(outgoingRequestsProvider.future);
    expect(result, fakeRepository.outgoingData);
  });

  test('friendsCoordinatesProvider returns coordinates', () async {
    final result = await container.read(friendsCoordinatesProvider.future);
    expect(result, fakeRepository.coordinatesData);
  });

  test('mutation helpers delegate to repository', () async {
    await container
        .read(friendsRepositoryProvider)
        .requestFriend('new@example.com');
    await container.read(friendsRepositoryProvider).acceptRequest('request-id');
    await container.read(friendsRepositoryProvider).rejectRequest('request-id');
    await container.read(friendsRepositoryProvider).removeFriend('friend-id');

    expect(fakeRepository.sentRequests, ['new@example.com']);
    expect(fakeRepository.acceptedRequests, ['request-id']);
    expect(fakeRepository.rejectedRequests, ['request-id']);
    expect(fakeRepository.removedFriends, ['friend-id']);
  });
}
