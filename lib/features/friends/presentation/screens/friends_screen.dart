// lib/features/friends/presentation/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/features/friends/data/friends_api.dart';
import 'package:ISS/l10n/app_localizations.dart';

import '../../domain/friends_models.dart';
import '../providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _emailCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  FriendsActions get _actions => ref.read(friendsActionsProvider);

  Future<void> _sendRequest() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _actions.requestFriend(email);
      if (!mounted) return;
      _emailCtrl.clear();
      _showSnack('Заявка отправлена');
    } catch (e) {
      _showSnack(_errorText(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _accept(String requestId) async {
    try {
      await _actions.acceptRequest(requestId);
      _showSnack('Заявка принята');
    } catch (e) {
      _showSnack(_errorText(e));
    }
  }

  Future<void> _reject(String requestId) async {
    try {
      await _actions.rejectRequest(requestId);
      _showSnack('Заявка отклонена');
    } catch (e) {
      _showSnack(_errorText(e));
    }
  }

  Future<void> _removeFriend(String friendId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Удалить из друзей?'),
            content: const Text('Действие нельзя отменить.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    try {
      await _actions.removeFriend(friendId);
      _showSnack('Удален из друзей');
    } catch (e) {
      _showSnack(_errorText(e));
    }
  }

  Future<void> _pullRefresh() async {
    ref.invalidate(friendsListProvider);
    ref.invalidate(incomingRequestsProvider);
    ref.invalidate(outgoingRequestsProvider);
    ref.invalidate(friendsCoordinatesProvider);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorText(Object error) {
    if (error is FriendsApiException) {
      return error.message;
    }
    return 'Ошибка: $error';
  }

  String _statusLabel(FriendRequestStatus status) {
    switch (status) {
      case FriendRequestStatus.pending:
        return 'В ожидании';
      case FriendRequestStatus.accepted:
        return 'Принята';
      case FriendRequestStatus.rejected:
        return 'Отклонена';
    }
  }

  String _formatRelative(DateTime ts, AppLocalizations loc) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return loc.homeMapUpdatedNow;
    if (diff.inMinutes < 60) return loc.homeMapUpdatedMinutes(diff.inMinutes);
    if (diff.inHours < 24) return loc.homeMapUpdatedHours(diff.inHours);
    return loc.homeMapUpdatedDays(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friendsAsync = ref.watch(friendsListProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final coordinatesAsync = ref.watch(friendsCoordinatesProvider);
    final currentEmail =
        ref.watch(currentUserEmailProvider).asData?.value?.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Друзья'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Список'),
            Tab(text: 'Заявки'),
            Tab(text: 'Координаты'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: TabBarView(
          controller: _tab,
          children: [
            // ---- Таб 1: Список друзей + форма отправки заявки ----
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Форма "Добавить по email"
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email друга',
                                  hintText: 'friend@example.com',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _sending ? null : _sendRequest,
                              icon: const Icon(Icons.person_add_alt_1),
                              label:
                                  _sending
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Добавить'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Отправь заявку пользователю по email.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Список друзей
                friendsAsync.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error:
                      (e, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_errorText(e)),
                      ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Пока нет друзей'),
                          subtitle: Text(
                            'Добавь первого друга сверху через email.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children:
                          list.map((f) {
                            final fullName = [f.firstName, f.lastName]
                                .where((part) => (part ?? '').trim().isNotEmpty)
                                .map((part) => part!.trim())
                                .join(' ');
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  fullName.isNotEmpty
                                      ? fullName
                                      : f.displayName,
                                ),
                                subtitle: Text(f.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeFriend(f.id),
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),

            // ---- Таб 2: Входящие/Исходящие заявки ----
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text('Входящие', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                incomingAsync.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (e, _) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_errorText(e)),
                      ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.inbox_outlined),
                          title: const Text('Нет входящих заявок'),
                        ),
                      );
                    }
                    return Column(
                      children:
                          list.map((r) {
                            final title = r.displayLabel(currentEmail);
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_add),
                                ),
                                title: Text(title),
                                subtitle: Text(
                                  'Статус: ${_statusLabel(r.status)}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.close),
                                      label: const Text('Отклонить'),
                                      onPressed: () => _reject(r.id),
                                    ),
                                    FilledButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('Принять'),
                                      onPressed: () => _accept(r.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('Исходящие', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                outgoingAsync.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (e, _) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_errorText(e)),
                      ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.outbox_outlined),
                          title: const Text('Нет исходящих заявок'),
                        ),
                      );
                    }
                    return Column(
                      children:
                          list.map((r) {
                            final title = r.displayLabel(currentEmail);
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.hourglass_top),
                                ),
                                title: Text(title),
                                subtitle: Text(
                                  'Статус: ${_statusLabel(r.status)}',
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),

            // ---- Таб 3: Координаты друзей ----
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                coordinatesAsync.when(
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (e, _) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_errorText(e)),
                      ),
                  data: (list) {
                    if (list.isEmpty) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.map_outlined),
                          title: const Text('Нет координат друзей'),
                          subtitle: const Text(
                            'У друзей пока нет активных геоданных.',
                          ),
                        ),
                      );
                    }
                    final loc = AppLocalizations.of(context);
                    return Column(
                      children:
                          list.map((c) {
                            final title = c.displayName;
                            final updated =
                                c.lastUpdated != null
                                    ? _formatRelative(c.lastUpdated!, loc)
                                    : '—';
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.place),
                                ),
                                title: Text(title),
                                subtitle: Text(
                                  'lat: ${c.latitude}, lon: ${c.longitude}\nОбновлено: $updated',
                                ),
                                isThreeLine: true,
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
