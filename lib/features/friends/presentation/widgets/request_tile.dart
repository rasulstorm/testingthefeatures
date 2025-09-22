// lib/features/friends/presentation/widgets/request_tile.dart
import 'package:flutter/material.dart';
import '../../../friends/domain/friends_models.dart' as fm;
import 'helpers.dart';

class RequestTile extends StatelessWidget {
  final fm.FriendRequest request;
  final bool incoming; // true = входящая, false = исходящая
  final VoidCallback? onAccept; // только для входящих
  final VoidCallback? onReject; // только для входящих

  const RequestTile({
    super.key,
    required this.request,
    required this.incoming,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        (request.friendFirstName ?? '').trim().isNotEmpty
            ? '${request.friendFirstName} ${request.friendLastName ?? ''}'
                .trim()
            : request.friendEmail;

    final initials = initialsOf(
      firstName: request.friendFirstName,
      lastName: request.friendLastName,
      email: request.friendEmail,
    );

    final color = avatarColorFromSeed(request.id, context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text('Статус: ${request.status.name}'),
        isThreeLine: false,
        trailing:
            incoming
                ? Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Отклонить'),
                      onPressed: onReject,
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Принять'),
                      onPressed: onAccept,
                    ),
                  ],
                )
                : const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Text(
                    'Ожидает',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
      ),
    );
  }
}
