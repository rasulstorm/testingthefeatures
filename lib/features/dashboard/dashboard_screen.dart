// lib/features/dashboard/dashboard_screen.dart

import 'package:ISS/features/main_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Keep if you use GoRouter elsewhere
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ISS/appColor.dart'; // Updated import if path changed
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Helper function for making GET requests with automatic token refresh
Future<Response> dioGetWithRefresh(String path) async {
  final prefs = await SharedPreferences.getInstance();

  final refreshToken = prefs.getString('refreshToken');
  if (refreshToken == null || refreshToken.isEmpty) {
    throw Exception('Refresh token not found. Please log in again.');
  }

  try {
    // Use a new Dio instance for the refresh call to avoid interceptor recursion
    final refreshDio = Dio(BaseOptions(
      baseUrl: dio.options.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final refreshResp = await refreshDio.post(
      '/account-management/refresh',
      data: {'refreshToken': refreshToken},
    );

    if (refreshResp.statusCode == 200) {
      final data = refreshResp.data['data'];
      final newAccessToken = data['accessToken'];
      final newRefreshToken = data['refreshToken'];

      await prefs.setString('accessToken', newAccessToken);
      await prefs.setString('refreshToken', newRefreshToken);

      // Use the global dio instance for the main request
      final response = await dio.get(
        path,
        options: Options(headers: {'Authorization': 'Bearer $newAccessToken'}),
      );
      return response;
    } else {
      throw DioException(
        requestOptions: refreshResp.requestOptions,
        response: refreshResp,
        type: DioExceptionType.badResponse,
        error: "Failed to refresh token: ${refreshResp.statusCode}",
      );
    }
  } catch (e) {
    print('Error during dioGetWithRefresh: $e');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    rethrow;
  }
}

final subscriptionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await dioGetWithRefresh('/user/contracts');
    final data = response.data;
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first);
    }
    return null;
  } catch (e) {
    print('Error fetching subscription: $e');
    rethrow;
  }
});

final paymentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final response = await dioGetWithRefresh('/payment/');
    final List data = response.data;
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (e) {
    print('Error fetching payments: $e');
    rethrow;
  }
});

final hasCardProvider = FutureProvider<bool>((ref) async {
  try {
    final response = await dioGetWithRefresh('/card/');
    final data = response.data;
    return data is List && data.isNotEmpty;
  } catch (e) {
    print('Error fetching hasCard: $e');
    rethrow;
  }
});

final cardInfoProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final response = await dioGetWithRefresh('/card/');
    final data = response.data;
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first);
    }
    return null;
  } catch (e) {
    print('Error fetching card info: $e');
    rethrow;
  }
});

class CardBindingWebViewPage extends ConsumerWidget {
  final String htmlContent;

  const CardBindingWebViewPage({super.key, required this.htmlContent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                final url = request.url;
                if (url.contains('success')) {
                  ref.invalidate(subscriptionProvider);
                  ref.invalidate(hasCardProvider);
                  ref.invalidate(paymentsProvider);
                  ref.invalidate(cardInfoProvider);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Карта успешно привязана')),
                  );
                  return NavigationDecision.prevent;
                }

                if (url.contains('error') || url.contains('fail')) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка при привязке карты')),
                  );
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
              onWebResourceError: (error) {
                if (error.description.contains('favicon') ||
                    error.errorCode == -6) {
                  return;
                }

                debugPrint(
                  'WebView error: ${error.errorCode} | ${error.description}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Ошибка загрузки WebView: ${error.description}',
                    ),
                  ),
                );
              },
            ),
          )
          ..loadRequest(Uri.parse(htmlContent));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Привязка карты'),
        backgroundColor: AppColors.secodnBg, // Using AppColors
        foregroundColor: AppColors.heading, // Using AppColors
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.heading, // Using AppColors
          ),
        ],
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

Future<String> fetchBindCardHtml() async {
  final response = await dio.get('/card/save');
  if (response.statusCode == 200) {
    return response.data.toString();
  }
  throw Exception('Ошибка загрузки HTML');
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(subscriptionProvider);
      ref.invalidate(hasCardProvider);
      ref.invalidate(paymentsProvider);
      ref.invalidate(cardInfoProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    final hasCard = ref.watch(hasCardProvider);
    final cardInfo = ref.watch(cardInfoProvider);
    final payments = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Главная'),
        backgroundColor: AppColors.secodnBg, // Using AppColors
        foregroundColor: AppColors.heading, // Using AppColors
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed:
                () => showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const MainMenuSheet(),
                ),
            color: AppColors.heading, // Using AppColors
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            subscription.when(
              data:
                  (data) => hasCard.when(
                    data: (isAttached) {
                      if (data == null || !isAttached) {
                        return buildNoSubscriptionCard(context);
                      } else {
                        return buildActiveSubscriptionCard(data, cardInfo);
                      }
                    },
                    loading:
                        () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), // Using AppColors
                    error:
                        (err, _) => buildErrorWidget(
                              ref,
                              hasCardProvider,
                              'Ошибка получения карты',
                            ),
                  ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)), // Using AppColors
              error:
                  (err, _) => buildErrorWidget(
                        ref,
                        subscriptionProvider,
                        'Ошибка загрузки подписки',
                      ),
            ),
            const SizedBox(height: 20),
            Text(
              "История платежей",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.heading, // Using AppColors
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                color: AppColors.background, // Using AppColors
                child: payments.when(
                  data:
                      (list) => ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final payment = list[index];
                              final status = payment['status'] == true;
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                color: AppColors.secodnBg, // Using AppColors
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    tileColor: AppColors.secodnBg, // Using AppColors
                                    isThreeLine: true,
                                    title: Text(
                                      "Сумма: ${payment['amount']} ₸",
                                      style: const TextStyle(
                                        color: AppColors.heading, // Using AppColors
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          "Дата: ${DateFormat('d MMMM y', 'ru_RU').format(DateTime.parse(payment['dateOfPayment']))}",
                                          style: const TextStyle(color: AppColors.text), // Using AppColors
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Описание: ${payment['description']}",
                                          style: const TextStyle(
                                            color: AppColors.text, // Using AppColors
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(
                                      status ? Icons.check_circle : Icons.error,
                                      color:
                                          status
                                              ? AppColors.iconGreen
                                              : AppColors.iconRed, // Using AppColors
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  loading:
                      () => const Center(
                              child: CircularProgressIndicator(color: AppColors.primary), // Using AppColors
                            ),
                  error:
                      (err, _) => buildErrorWidget(
                            ref,
                            paymentsProvider,
                            'Ошибка загрузки платежей',
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNoSubscriptionCard(BuildContext context) {
    return Card(
      elevation: 2,
      color: AppColors.secodnBg, // Using AppColors
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Подписка не активна",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.heading), // Using AppColors
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)), // Using AppColors
                );
                try {
                  final html = await fetchBindCardHtml();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => CardBindingWebViewPage(htmlContent: html),
                      ),
                    );
                  }
                } catch (_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка загрузки формы привязки'),
                      backgroundColor: AppColors.iconRed, // Using AppColors
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Using AppColors
                foregroundColor: AppColors.heading, // Using AppColors
              ),
              child: const Text("Привязать карту"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildActiveSubscriptionCard(
    Map<String, dynamic> data,
    AsyncValue<Map<String, dynamic>?> cardInfo,
  ) {
    final sum = data['sum'] ?? 0;
    final dateNext =
        data['dateNextPayment'] != null
            ? DateFormat(
                'd MMMM y',
                'ru_RU',
              ).format(DateTime.parse(data['dateNextPayment']))
            : 'неизвестно';

    return Card(
      elevation: 2,
      color: AppColors.secodnBg, // Using AppColors
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Абонентская плата: $sum ₸",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.heading, // Using AppColors
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Статус: Активна",
              style: TextStyle(fontSize: 16, color: AppColors.iconGreen), // Using AppColors for green status
            ),
            const SizedBox(height: 8),
            cardInfo.when(
              data: (card) {
                final cardMask = card?['cardMask'] ?? '';
                return Text(
                  "Карта: $cardMask",
                  style: const TextStyle(fontSize: 14, color: AppColors.text), // Using AppColors
                );
              },
              loading: () => const CircularProgressIndicator(color: AppColors.primary), // Using AppColors
              error:
                  (err, _) => const Text(
                        "Ошибка загрузки карты",
                        style: TextStyle(color: AppColors.iconRed), // Using AppColors
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              "Следующее списание: $dateNext",
              style: const TextStyle(color: AppColors.text), // Using AppColors
            ),
            const SizedBox(height: 12),
            // Удалена строка с кнопкой "Связаться с поддержкой"
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Карта привязана",
                  style: TextStyle(color: AppColors.heading, fontSize: 16), // Using AppColors
                ),
                // Здесь раньше был TextButton.icon для "Связаться с поддержкой"
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildErrorWidget(
    WidgetRef ref,
    ProviderBase provider,
    String message,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: AppColors.iconRed)), // Using AppColors
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => ref.invalidate(provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Using AppColors
            foregroundColor: AppColors.heading, // Using AppColors
          ),
          child: const Text('Обновить'),
        ),
      ],
    );
  }
}