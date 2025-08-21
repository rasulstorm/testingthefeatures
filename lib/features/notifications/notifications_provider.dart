// lib/features/notifications/notifications_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:intl/intl.dart';
import 'package:ISS/l10n/app_localizations.dart';

// Провайдер состояния
final notificationsProvider = StateNotifierProvider.autoDispose<
  NotificationsNotifier,
  NotificationsState
>((ref) => NotificationsNotifier());

// Модель данных
class NotificationItem implements Comparable<NotificationItem> {
  // <--- ДОБАВЛЯЕМ Comparable
  final String title;
  final String description;
  final DateTime dateTime;

  NotificationItem({
    required this.title,
    required this.description,
    required this.dateTime,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'] ?? 'Без заголовка',
      description: json['description'] ?? 'Без описания',
      dateTime: DateTime.parse(json['dateTime']),
    );
  }

  // --- НОВЫЙ МЕТОД ДЛЯ СОРТИРОВКИ ---
  // Сравниваем этот объект с другим. Мы хотим, чтобы более новые даты были "меньше" (шли раньше)
  @override
  int compareTo(NotificationItem other) {
    return other.dateTime.compareTo(dateTime);
  }

  // ------------------------------------
}

// Класс состояния
class NotificationsState {
  final List<NotificationItem> items;
  final bool isLoading;
  final bool hasMore;

  NotificationsState({
    required this.items,
    this.isLoading = false,
    this.hasMore = true,
  });

  NotificationsState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    bool? hasMore,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// Notifier - контроллер
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationsState(items: [])) {
    fetchNextPage();
  }

  int _page = 0;
  final int _limit = 10;
  bool _isFetching = false;

  Future<void> fetchNextPage() async {
    if (_isFetching || !state.hasMore) return;

    _isFetching = true;
    state = state.copyWith(isLoading: true);

    try {
      final response = await dio.post(
        '/mobile/hub/notifications',
        data: {'page': _page, 'size': _limit},
      );

      final topLevelData = response.data['data'];
      final List rawItems = topLevelData['data'] ?? [];
      final bool hasNext = topLevelData['hasNext'] ?? false;

      final newItems =
          rawItems.map((e) => NotificationItem.fromJson(e)).toList();

      // -- ИСПРАВЛЕНИЕ ЗДЕСЬ: СОРТИРУЕМ ОБЩИЙ СПИСОК --
      final allItems = [...state.items, ...newItems];
      allItems.sort(); // Используем наш метод compareTo
      // ---------------------------------------------

      state = state.copyWith(
        items: allItems, // Передаем отсортированный список
        hasMore: hasNext,
        isLoading: false,
      );
      _page++;
    } catch (e) {
      if (e is DioException) {
        print('Error fetching notifications: ${e.response?.data}');
      } else {
        print('Error fetching notifications: $e');
      }
      state = state.copyWith(isLoading: false, hasMore: false);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    _page = 0;
    _isFetching = false;
    state = NotificationsState(items: [], hasMore: true);
    await fetchNextPage();
  }
}

// UI - Экран
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final notificationsNotifier = ref.read(notificationsProvider.notifier);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.notificationsTitle),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: notificationsNotifier.refresh,
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.getCardBackgroundColor(context),
        child:
            (notificationsState.isLoading && notificationsState.items.isEmpty)
                ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                )
                : notificationsState.items.isEmpty
                ? Center(
                  child: Text(
                    localizations.noNotifications,
                    style: AppStyles.bodyText1(
                      context,
                    ).copyWith(color: AppColors.getSecondaryTextColor(context)),
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount:
                      notificationsState.items.length +
                      (notificationsState.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == notificationsState.items.length) {
                      if (notificationsState.hasMore) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (ref.read(notificationsProvider).isLoading ==
                              false) {
                            notificationsNotifier.fetchNextPage();
                          }
                        });
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final notification = notificationsState.items[index];
                    final date = DateFormat(
                      'd MMMM y, HH:mm',
                      'ru_RU',
                    ).format(notification.dateTime);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: AppStyles.cardDecoration(context),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppStyles.headline4(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.description,
                              style: AppStyles.bodyText1(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${localizations.date}: $date',
                              style: AppStyles.bodyText2(context).copyWith(
                                color: AppColors.getSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
