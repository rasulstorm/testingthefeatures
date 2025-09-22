// lib/features/friends/domain/friends_models.dart
enum FriendRequestStatus { pending, accepted, rejected }

FriendRequestStatus _statusFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'ACCEPTED':
      return FriendRequestStatus.accepted;
    case 'REJECTED':
      return FriendRequestStatus.rejected;
    default:
      return FriendRequestStatus.pending;
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt(),
      isUtc: true,
    ).toLocal();
  }
  final parsed = DateTime.tryParse(value.toString());
  return parsed;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

class Friend {
  Friend({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    this.friendshipCreatedAt,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? friendshipCreatedAt;

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: (json['id'] ?? json['friendId'] ?? '').toString(),
      email: (json['email'] ?? json['friendEmail'] ?? '').toString(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      friendshipCreatedAt: _parseDateTime(json['friendshipCreatedAt']),
    );
  }

  String get displayName {
    final name = [firstName, lastName]
        .map((part) => part?.trim())
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return id;
  }

  String get initials {
    final nameParts =
        [firstName, lastName]
            .map((part) => part?.trim())
            .whereType<String>()
            .where((part) => part.isNotEmpty)
            .toList();
    if (nameParts.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    return nameParts.map((part) => part[0].toUpperCase()).join();
  }
}

class FriendRequest {
  FriendRequest({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.status,
    required this.createdAt,
    this.message,
    this.requesterEmail,
    this.recipientEmail,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final String? message;
  final String? requesterEmail;
  final String? recipientEmail;

  String? get friendFirstName => firstName;
  String? get friendLastName => lastName;
  String get friendEmail => email;

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    String? readString(dynamic value) => value?.toString();

    final friendEmail =
        readString(json['friendEmail']) ??
        readString(json['email']) ??
        readString(json['recipientEmail']) ??
        readString(json['targetEmail']) ??
        '';

    return FriendRequest(
      id: (json['id'] ?? json['requestId']).toString(),
      email: friendEmail,
      firstName:
          json['friendFirstName'] as String? ?? json['firstName'] as String?,
      lastName:
          json['friendLastName'] as String? ?? json['lastName'] as String?,
      status: _statusFromString(json['status'] as String?),
      createdAt:
          _parseDateTime(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      message: json['message'] as String?,
      requesterEmail:
          readString(json['requesterEmail']) ??
          readString(json['senderEmail']) ??
          readString(json['initiatorEmail']) ??
          readString(json['fromEmail']),
      recipientEmail:
          readString(json['recipientEmail']) ??
          readString(json['targetEmail']) ??
          readString(json['toEmail']) ??
          friendEmail,
    );
  }

  String get displayName {
    final name = [firstName, lastName]
        .map((part) => part?.trim())
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (name.isNotEmpty) return name;
    if (email.isNotEmpty) return email;
    return id;
  }

  String get initials {
    final nameParts =
        [firstName, lastName]
            .map((part) => part?.trim())
            .whereType<String>()
            .where((part) => part.isNotEmpty)
            .toList();
    if (nameParts.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    return nameParts.map((part) => part[0].toUpperCase()).join();
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed.toLowerCase();
  }

  String? counterpartEmail(String? currentUserEmail) {
    final normalizedCurrent = _normalize(currentUserEmail);
    final candidates =
        <String?>[email, requesterEmail, recipientEmail]
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();

    if (normalizedCurrent != null) {
      for (final candidate in candidates) {
        if (candidate.toLowerCase() != normalizedCurrent) {
          return candidate;
        }
      }
    }

    return candidates.isNotEmpty ? candidates.first : null;
  }

  bool isIncomingFor(String? currentUserEmail) {
    final normalizedCurrent = _normalize(currentUserEmail);
    if (normalizedCurrent == null) return false;
    final recipient = _normalize(recipientEmail);
    return recipient == normalizedCurrent;
  }

  String displayLabel(String? currentUserEmail) {
    final name = [firstName, lastName]
        .map((part) => part?.trim())
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (name.isNotEmpty) return name;
    return counterpartEmail(currentUserEmail) ?? email;
  }
}

class FriendCoordinate {
  FriendCoordinate({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.firstName,
    this.lastName,
    this.email,
    this.avatarUrl,
    this.online,
    this.lastUpdated,
  });

  final String userId;
  final double latitude;
  final double longitude;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? avatarUrl;
  final bool? online;
  final DateTime? lastUpdated;

  factory FriendCoordinate.fromJson(Map<String, dynamic> json) {
    return FriendCoordinate(
      userId: (json['userId'] ?? json['friendId'] ?? '').toString(),
      latitude: _parseDouble(json['latitude']) ?? 0,
      longitude: _parseDouble(json['longitude']) ?? 0,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      online: json['online'] as bool?,
      lastUpdated: _parseDateTime(json['lastUpdated']),
    );
  }

  String get displayName {
    final name = [firstName, lastName]
        .map((part) => part?.trim())
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (name.isNotEmpty) return name;
    if ((email ?? '').isNotEmpty) return email!;
    return userId;
  }

  String get initials {
    final nameParts =
        [firstName, lastName]
            .map((part) => part?.trim())
            .whereType<String>()
            .where((part) => part.isNotEmpty)
            .toList();
    if (nameParts.isEmpty) {
      final str = (email ?? userId);
      return str.isNotEmpty ? str[0].toUpperCase() : '?';
    }
    return nameParts.map((part) => part[0].toUpperCase()).join();
  }

  bool get isOnline => online ?? false;
}
