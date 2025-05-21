// notifications_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationItem {
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
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
    );
  }
}

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

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationsState(items: [])) {
    fetchNextPage();
  }

  int _page = 0;
  final int _limit = 10;
  bool _isFetching = false;

  Future<String> _refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) throw Exception("Refresh token не найден");

    final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
    final response = await refreshDio.post(
      '/account-management/refresh',
      data: {'refreshToken': refreshToken},
    );

    final data = response.data['data'];
    final accessToken = data['accessToken'];
    final refreshTokenNew = data['refreshToken'];

    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshTokenNew);
    return accessToken;
  }

  Future<void> fetchNextPage() async {
    if (_isFetching || !state.hasMore) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true);

    try {
      final token = await _refreshAccessToken();

      final response = await dio.post(
        'https://cms.iss-control.kz:8443/api/v1/mobile/hub/notifications',
        data: {'page': _page, 'size': _limit},
        options: Options(headers: {'Authorization': token}),
      );

      final pageData = response.data['data'];
      final List raw = pageData['data'] ?? [];
      print(pageData);
      final hasNext = pageData['hasNext'] ?? false;

      final newItems = raw.map((e) => NotificationItem.fromJson(e)).toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        hasMore: hasNext,
        isLoading: false,
      );
      _page++;
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }

    _isFetching = false;
  }

  Future<void> refresh() async {
    _page = 0;
    state = NotificationsState(items: []);
    await fetchNextPage();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
      (ref) => NotificationsNotifier(),
    );
