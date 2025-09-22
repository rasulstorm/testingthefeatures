// lib/features/friends/presentation/widgets/friend_tile.dart
import 'package:flutter/material.dart';
import '../../../friends/domain/friends_models.dart' as fm;
import 'helpers.dart';

class FriendTile extends StatelessWidget {
  final fm.Friend friend;
  final VoidCallback? onRemove;
  final Widget? trailing;

  const FriendTile({
    super.key,
    required this.friend,
    this.onRemove,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        (friend.firstName ?? '').trim().isNotEmpty
            ? '${friend.firstName} ${friend.lastName ?? ''}'.trim()
            : friend.email;

    final initials = initialsOf(
      firstName: friend.firstName,
      lastName: friend.lastName,
      email: friend.email,
    );

    final avatarColor = avatarColorFromSeed(
      friend.id.isNotEmpty ? friend.id : friend.email,
      context,
    );

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Text(friend.email),
        trailing:
            trailing ??
            (onRemove == null
                ? null
                : IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                )),
      ),
    );
  }
}
