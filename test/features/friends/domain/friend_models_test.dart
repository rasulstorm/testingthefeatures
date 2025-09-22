import 'package:flutter_test/flutter_test.dart';
import 'package:ISS/features/friends/domain/friends_models.dart';

void main() {
  group('Friend.fromJson', () {
    test('parses primary fields and display helpers', () {
      final json = {
        'friendId': '123',
        'friendEmail': 'user@example.com',
        'firstName': 'Alice',
        'lastName': 'Smith',
        'phoneNumber': '+1234567890',
        'avatarUrl': 'https://example.com/avatar.png',
        'friendshipCreatedAt': '2024-01-01T12:00:00Z',
      };

      final friend = Friend.fromJson(json);

      expect(friend.id, '123');
      expect(friend.email, 'user@example.com');
      expect(friend.displayName, 'Alice Smith');
      expect(friend.initials, 'AS');
      expect(friend.friendshipCreatedAt, isNotNull);
      expect(
        friend.friendshipCreatedAt!.toUtc(),
        DateTime.parse('2024-01-01T12:00:00Z'),
      );
    });

    test('falls back to email when name missing', () {
      final json = {'id': '987', 'email': 'friend@sample.kz'};

      final friend = Friend.fromJson(json);

      expect(friend.displayName, 'friend@sample.kz');
      expect(friend.initials, 'F');
    });
  });

  group('FriendRequest.fromJson', () {
    test('parses alternative field names and status', () {
      final json = {
        'requestId': 'req-1',
        'friendEmail': 'requester@example.com',
        'friendFirstName': 'Bob',
        'friendLastName': 'Jones',
        'status': 'accepted',
        'createdAt': '2024-02-10T08:30:00+03:00',
        'message': 'Hi!',
      };

      final request = FriendRequest.fromJson(json);

      expect(request.id, 'req-1');
      expect(request.email, 'requester@example.com');
      expect(request.status, FriendRequestStatus.accepted);
      expect(request.displayName, 'Bob Jones');
      expect(request.initials, 'BJ');
      expect(request.message, 'Hi!');
      expect(request.createdAt.toUtc(), DateTime.parse('2024-02-10T05:30:00Z'));
    });

    test('handles unix timestamp in milliseconds', () {
      final createdAt = DateTime.utc(2024, 03, 01, 12, 0, 0);
      final json = {
        'id': 'req-2',
        'email': 'friend@example.com',
        'status': 'pending',
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

      final request = FriendRequest.fromJson(json);

      expect(request.createdAt.toUtc(), createdAt);
      expect(request.status, FriendRequestStatus.pending);
    });
  });

  group('FriendCoordinate.fromJson', () {
    test('parses numeric latitude and longitude', () {
      final json = {
        'userId': 'user-1',
        'latitude': 43.2567,
        'longitude': 76.9286,
        'firstName': 'Dana',
        'lastName': 'Khan',
        'online': true,
        'lastUpdated': '2024-02-20T10:15:00Z',
      };

      final coordinate = FriendCoordinate.fromJson(json);

      expect(coordinate.userId, 'user-1');
      expect(coordinate.latitude, closeTo(43.2567, 0.0001));
      expect(coordinate.longitude, closeTo(76.9286, 0.0001));
      expect(coordinate.isOnline, isTrue);
      expect(
        coordinate.lastUpdated!.toUtc(),
        DateTime.parse('2024-02-20T10:15:00Z'),
      );
    });

    test('parses string coordinates and falls back to identifiers', () {
      final json = {
        'friendId': 'f-007',
        'latitude': '51.1694',
        'longitude': '71.4491',
        'email': 'astana@example.kz',
      };

      final coordinate = FriendCoordinate.fromJson(json);

      expect(coordinate.userId, 'f-007');
      expect(coordinate.displayName, 'astana@example.kz');
      expect(coordinate.initials, 'A');
      expect(coordinate.latitude, closeTo(51.1694, 0.0001));
      expect(coordinate.longitude, closeTo(71.4491, 0.0001));
    });
  });
}
