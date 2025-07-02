import 'package:ISS/features/main_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/features/security_control/security_provider.dart'; // Ensure this path is correct
import 'package:ISS/features/security_control/object_modal_bottom_sheet.dart';
import 'package:ISS/models/hub_models.dart'; // Import the new models
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Your existing dioGetWithRefresh and sendFcmTokenToBackend functions remain unchanged
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

  final response = await dio.post( // Changed to post as per getObjects endpoint
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
      // Adjusted to use dio.post for notificationToken
      final newTokenResponse = await dioGetWithRefresh(
        '/user/notificationToken?token=$token', // This will now correctly call POST via dioGetWithRefresh
      );
      print(' Повторная отправка успешна: ${newTokenResponse.statusCode}');
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
      if (token != null) { // Ensure token is not null before sending
        sendFcmTokenToBackend(token);
      }
    });

    FirebaseMessaging.instance.requestPermission().then((settings) async {
      print('Push permission: ${settings.authorizationStatus}');
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) { // Ensure token is not null before printing
          print('FCM Token: $token');
        }
      } catch (e) {
        print('FCM getToken error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final objectsAsync = ref.watch(objectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background, // Set background color
      appBar: AppBar(
        title: const Text(
          'Объекты',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.secodnBg, // Set AppBar color
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => showModalBottomSheet(
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
              color: AppColors.primary, // Color of refresh indicator
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      "Нет объектов",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
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
            color: AppColors.primary, // Color of refresh indicator
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: objects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final obj = objects[index];
                final bool isConnected = obj.connected; // Use the parsed boolean status
                final Color statusColor = isConnected ? AppColors.iconGreen : AppColors.primary;


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
                      obj.facilityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obj.address,
                          style: const TextStyle(color: AppColors.text, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID Хаба: ${obj.hubNumber}', // Display hubNumber
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            obj.statusNameRus, // Use parsed statusNameRus
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ObjectModalBottomSheet(
                        object: obj, // Pass the parsed HubObject
                        rootContext: context,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Ошибка загрузки объектов: $e",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(objectsProvider), // Invalidate the provider on retry
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const AddHubDialog(),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
        // Ensure this endpoint is correct and handles POST requests for attachment
        'https://cms.iss-control.kz:8443/api/v1/mobile/hub/$hubId/attach',
      );

      // Check the actual response structure for success/error
      // Assuming 'code' 1 is an error as per your original code's throw logic.
      // If code 1 is actually success, adjust this logic.
      if (response.data != null && response.data['code'] == 1) {
         // This condition implies an error based on your previous code logic.
         // You might want to display response.data['message'] if it's an error message.
         throw Exception(response.data['message'] ?? 'Неизвестная ошибка при привязке хаба.');
      } else if (response.statusCode != 200) {
         throw Exception('Ошибка сервера: ${response.statusCode}');
      }


      ref.invalidate(objectsProvider); // Invalidate to refresh the list

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Хаб успешно добавлен')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка при добавлении хаба: $e')));
      }
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
        decoration: InputDecoration(
          labelText: 'Номер объекта',
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder( // Add border styling
            borderSide: const BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Отмена',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20, // Slightly larger for better visibility
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Добавить'),
        ),
      ],
    );
  }
}