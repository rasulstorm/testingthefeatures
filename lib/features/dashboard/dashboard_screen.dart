import 'package:ISS/features/main_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ISS/appColor.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final response = await dio.get(
    path,
    options: Options(headers: {'Authorization': '$newAccessToken'}),
  );

  return response;
}

final subscriptionProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final response = await dioGetWithRefresh('/user/contracts');
  final data = response.data;
  if (data is List && data.isNotEmpty) {
    return Map<String, dynamic>.from(data.first);
  }
  return null;
});

final paymentsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final response = await dioGetWithRefresh('/payment/');
  final List data = response.data;
  return data.map((e) => Map<String, dynamic>.from(e)).toList();
});

final hasCardProvider = FutureProvider<bool>((ref) async {
  final response = await dioGetWithRefresh('/card/');
  final data = response.data;
  return data is List && data.isNotEmpty;
});

final cardInfoProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final response = await dioGetWithRefresh('/card/');
  final data = response.data;
  if (data is List && data.isNotEmpty) {
    return Map<String, dynamic>.from(data.first);
  }
  return null;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
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

Future<void> unbindCard(
  BuildContext context,
  WidgetRef ref,
  String cardId,
) async {
  try {
    await dio.delete('/card/$cardId');
    ref.invalidate(hasCardProvider);
    ref.invalidate(cardInfoProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Карта успешно отвязана')));
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ошибка при отвязке карты')));
  }
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
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (err, _) => buildErrorWidget(
                          ref,
                          hasCardProvider,
                          'Ошибка получения карты',
                        ),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
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
                color: AppColors.heading,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                color: AppColors.background,
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
                            color: AppColors.background,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                tileColor: AppColors.secodnBg,
                                isThreeLine: true,
                                title: Text(
                                  "Сумма: ${payment['amount']} ₸",
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Описание: ${payment['description']}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  status ? Icons.check_circle : Icons.error,
                                  color:
                                      status
                                          ? AppColors.iconGreen
                                          : AppColors.iconRed,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Подписка не активна",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (_) => const Center(child: CircularProgressIndicator()),
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
                    ),
                  );
                }
              },
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Статус: Активна",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 8),
            cardInfo.when(
              data: (card) {
                final cardMask = card?['cardMask'] ?? '';
                return Text(
                  "Карта: $cardMask",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error:
                  (err, _) => const Text(
                    "Ошибка загрузки карты",
                    style: TextStyle(color: Colors.red),
                  ),
            ),
            const SizedBox(height: 8),
            Text("Следующее списание: $dateNext"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Карта привязана",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                cardInfo.when(
                  data: (card) {
                    if (card == null) return const SizedBox();
                    return TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                backgroundColor: AppColors.secodnBg,
                                title: const Text(
                                  'Подтвердите',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Вы уверены, что хотите отвязать карту?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  ElevatedButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    child: const Text('Отвязать'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text(
                                      'Отмена',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          await unbindCard(context, ref, card['id'].toString());
                        }
                      },
                      icon: const Icon(Icons.link_off, color: Colors.redAccent),
                      label: const Text(
                        "Отвязать карту",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error:
                      (err, _) => buildErrorWidget(
                        ref,
                        cardInfoProvider,
                        'Ошибка загрузки карты',
                      ),
                ),
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
        Text(message, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => ref.invalidate(provider),
          child: const Text('Обновить'),
        ),
      ],
    );
  }
}
