import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/main_menu_sheet.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(notificationsProvider.notifier).refresh();
    });

    _scrollController.addListener(() {
      final notifier = ref.read(notificationsProvider.notifier);
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        notifier.fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(notificationsProvider.notifier).refresh();
  }

  String formatDateLabel(String rawDate) {
    final now = DateTime.now();
    final today = DateFormat('dd.MM.yyyy').format(now);
    final yesterday = DateFormat(
      'dd.MM.yyyy',
    ).format(now.subtract(const Duration(days: 1)));

    if (rawDate == today) return 'Сегодня';
    if (rawDate == yesterday) return 'Вчера';
    return rawDate;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    final grouped = groupBy<NotificationItem, String>(
      state.items,
      (item) => DateFormat('dd.MM.yyyy').format(item.dateTime),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const MainMenuSheet(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (state.items.isEmpty && !state.isLoading) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: Center(
                    child: Text(
                      'Нет уведомлений',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: grouped.length + (state.isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= grouped.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final rawDate = grouped.keys.elementAt(i);
                final dateLabel = formatDateLabel(rawDate);
                final items = grouped[rawDate]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secodnBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(item.dateTime),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          leading: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
