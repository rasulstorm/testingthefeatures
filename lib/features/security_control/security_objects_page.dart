import 'package:ISS/features/main_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../appColor.dart';
import './security_provider.dart';
import 'object_modal_bottom_sheet.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<Response> dioGetWithRefresh(String path) async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refreshToken');
  if (refreshToken == null) throw Exception('No refresh token');

  final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
  final refreshResp = await refreshDio.post(
    '/account-management/refresh',
    data: {'refreshToken': refreshToken},
  );

  final data = refreshResp.data['data'];
  final newAccessToken = data['accessToken'];
  final newRefreshToken = data['refreshToken'];

  await prefs.setString('accessToken', newAccessToken);
  await prefs.setString('refreshToken', newRefreshToken);

  final response = await dio.post(
    path,
    options: Options(headers: {'Authorization': '$newAccessToken'}),
  );

  return response;
}

Future<void> sendFcmTokenToBackend(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    if (accessToken == null) throw Exception('Нет accessToken');

    final response = await dio.post(
      '/user/notificationToken',
      queryParameters: {'token': token},
      options: Options(headers: {'Authorization': accessToken}),
    );

    print('FCM токен отправлен: ${response.statusCode}');
  } catch (e) {
    print('Ошибка отправки токена: $e');
    try {
      final newToken = await dioGetWithRefresh(
        '/user/notificationToken?token=$token',
      );
      print(' Повторная отправка успешна: ${newToken.statusCode}');
    } catch (refreshError) {
      print('Ошибка при повторной отправке после refresh: $refreshError');
    }
  }
}

class SecurityObjectsPage extends ConsumerStatefulWidget {
  const SecurityObjectsPage({super.key});

  @override
  ConsumerState<SecurityObjectsPage> createState() =>
      _SecurityObjectsPageState();
}

class _SecurityObjectsPageState extends ConsumerState<SecurityObjectsPage> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Уведомление';
      final body = message.notification?.body ?? 'Сообщение';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title: $body')));
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('Новый FCM токен: $newToken');
      sendFcmTokenToBackend(newToken);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Уведомление открыто пользователем');
    });

    FirebaseMessaging.instance.getToken().then((token) {
      print('📲 FCM Token: $token');
      sendFcmTokenToBackend(token!);
    });

    FirebaseMessaging.instance.requestPermission().then((settings) async {
      print('Push permission: ${settings.authorizationStatus}');
      try {
        final token = await FirebaseMessaging.instance.getToken();
        print('FCM Token: $token');
      } catch (e) {
        print('FCM getToken error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final objectsAsync = ref.watch(objectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Объекты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const MainMenuSheet(),
                ),
          ),
        ],
      ),
      body: objectsAsync.when(
        data: (objects) {
          if (objects.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(objectsProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      "Нет объектов",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(objectsProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: objects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final obj = objects[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.secodnBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      obj['facilityName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      obj['address'],
                      style: const TextStyle(color: AppColors.text),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          obj['hubStatus']['description'] ?? '',
                          style: TextStyle(
                            color:
                                obj['hubStatus']['name'] == 'SECURITY_ACTIVE'
                                    ? AppColors.iconGreen
                                    : AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                    onTap:
                        () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder:
                              (context) => ObjectModalBottomSheet(
                                object: obj,
                                rootContext: context,
                              ),
                        ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                "Ошибка: $e",
                style: const TextStyle(color: Colors.red),
              ),
            ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed:
            () => showDialog(
              context: context,
              builder: (_) => const AddHubDialog(),
            ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddHubDialog extends ConsumerStatefulWidget {
  const AddHubDialog({super.key});

  @override
  ConsumerState<AddHubDialog> createState() => _AddHubDialogState();
}

class _AddHubDialogState extends ConsumerState<AddHubDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final hubId = _controller.text.trim();
    if (hubId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await dioGetWithRefresh(
        'https://cms.iss-control.kz:8443/api/v1/mobile/hub/$hubId/attach',
      );

      if (response.statusCode == 200 && response.data['code'] == 1) {
        throw Exception(response.data['message'] ?? 'Ошибка при привязке хаба');
      }

      ref.invalidate(objectsProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Хаб успешно добавлен')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.secodnBg,
      title: const Text(
        'Добавить объект',
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          labelText: 'Номер объекта',
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child:
              _isLoading
                  ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Добавить'),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}
