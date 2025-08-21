// lib/features/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ISS/l10n/app_localizations.dart';

// --- ПРОВАЙДЕРЫ ---

final cardListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final response = await dioGetWithRefresh('/card/');

      // ИСПРАВЛЕНИЕ ЗДЕСЬ: Сервер возвращает список напрямую, без ключа 'data'.
      final List data = response.data;

      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error fetching card list: $e');
      rethrow;
    }
  },
);

// --- СУЩЕСТВУЮЩИЕ ПРОВАЙДЕРЫ (остаются без изменений) ---

Future<Response> dioGetWithRefresh(String path) async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refreshToken');
  if (refreshToken == null || refreshToken.isEmpty) {
    throw Exception('Refresh token not found. Please log in again.');
  }
  try {
    final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
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
      return await dio.get(
        path,
        options: Options(headers: {'Authorization': 'Bearer $newAccessToken'}),
      );
    } else {
      throw DioException(
        requestOptions: refreshResp.requestOptions,
        response: refreshResp,
      );
    }
  } catch (e) {
    print('Error during dioGetWithRefresh: $e');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    rethrow;
  }
}

final subscriptionProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async {
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

final paymentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final response = await dioGetWithRefresh('/payment/');
      final List data = response.data;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error fetching payments: $e');
      rethrow;
    }
  },
);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshAllData());
  }

  Future<void> _refreshAllData() async {
    ref.invalidate(subscriptionProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(cardListProvider);
  }

  Future<void> _openTicketUrl(String? urlString) async {
    final localizations = AppLocalizations.of(context);
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.receiptNotAvailable)),
      );
      return;
    }
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.couldNotOpenReceipt}: $urlString'),
        ),
      );
    }
  }

  Future<void> _setPrimaryCard(String cardId) async {
    final localizations = AppLocalizations.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(child: CircularProgressIndicator()),
      );
      await dio.post('/card/setPrimaryFlag', data: {'cardId': cardId});
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.primaryCardSetSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      _refreshAllData();
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.primaryCardSetError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _bindCardAction() async {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
    try {
      final html = await fetchBindCardHtml();
      if (mounted) {
        Navigator.of(context).pop();
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CardBindingWebViewPage(htmlContent: html),
          ),
        );
        _refreshAllData();
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.errorLoadingBindForm),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final subscription = ref.watch(subscriptionProvider);
    final payments = ref.watch(paymentsProvider);
    final cardList = ref.watch(cardListProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              subscription.when(
                data:
                    (data) => cardList.when(
                      data: (cards) {
                        if (data == null || cards.isEmpty) {
                          return buildNoSubscriptionCard(
                            context,
                            localizations,
                          );
                        } else {
                          return buildActiveSubscriptionCard(
                            context,
                            localizations,
                            data,
                            cards,
                          );
                        }
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error:
                          (err, _) => buildErrorWidget(
                            ref,
                            cardListProvider,
                            localizations.errorLoadingCardInfo,
                          ),
                    ),
                loading: () => Center(child: CircularProgressIndicator()),
                error:
                    (err, _) => buildErrorWidget(
                      ref,
                      subscriptionProvider,
                      localizations.errorLoadingSubscription,
                    ),
              ),
              const SizedBox(height: 30),
              Text(localizations.myCards, style: AppStyles.headline4(context)),
              const SizedBox(height: 10),
              cardList.when(
                data: (cards) => buildCardList(context, localizations, cards),
                loading: () => Center(child: CircularProgressIndicator()),
                error:
                    (err, _) => buildErrorWidget(
                      ref,
                      cardListProvider,
                      localizations.errorLoadingCardInfo,
                    ),
              ),
              const SizedBox(height: 30),
              Text(
                localizations.paymentHistory,
                style: AppStyles.headline4(context),
              ),
              const SizedBox(height: 10),
              payments.when(
                data:
                    (list) =>
                        list.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: Text(
                                  localizations.noPaymentRecords,
                                  style: AppStyles.bodyText2(context),
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final payment = list[index];
                                final status = payment['status'] == true;
                                final ticketUrl = payment['ticketURL'];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: InkWell(
                                    onTap:
                                        ticketUrl != null
                                            ? () => _openTicketUrl(ticketUrl)
                                            : null,
                                    borderRadius: AppStyles.borderRadiusAll(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "${localizations.amount}: ${payment['amount']} ₸",
                                                  style: AppStyles.bodyText1(
                                                    context,
                                                  ).copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                status
                                                    ? Icons.check_circle
                                                    : Icons.error,
                                                color:
                                                    status
                                                        ? AppColors.success
                                                        : AppColors.error,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "${localizations.date}: ${DateFormat('d MMMM y', 'ru_RU').format(DateTime.parse(payment['dateOfPayment']))}",
                                            style: AppStyles.bodyText2(context),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${localizations.description}: ${payment['description']}",
                                            style: AppStyles.bodyText2(context),
                                          ),
                                          if (ticketUrl != null) ...[
                                            const SizedBox(height: 12),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton.icon(
                                                icon: Icon(
                                                  Icons.receipt_long,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  localizations.viewReceipt,
                                                ),
                                                onPressed:
                                                    () => _openTicketUrl(
                                                      ticketUrl,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                loading: () => Center(child: CircularProgressIndicator()),
                error:
                    (err, _) => buildErrorWidget(
                      ref,
                      paymentsProvider,
                      localizations.errorLoadingPayments,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCardList(
    BuildContext context,
    AppLocalizations localizations,
    List<Map<String, dynamic>> cards,
  ) {
    return Container(
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        children: [
          if (cards.isEmpty)
            ListTile(
              title: Center(
                child: Text(
                  localizations.noCards,
                  style: AppStyles.bodyText2(context),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final card = cards[index];
                final bool isPrimary = card['isPrimary'] ?? false;
                final String cardId = card['id'] ?? '';
                return ListTile(
                  leading: Icon(
                    Icons.credit_card,
                    color: AppColors.primaryAccent,
                  ),
                  title: Text(
                    card['cardMask'] ?? '**** **** **** ****',
                    style: AppStyles.bodyText1(context),
                  ),
                  subtitle:
                      isPrimary
                          ? Text(
                            localizations.primaryCard,
                            style: AppStyles.bodyText2(context).copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                  trailing:
                      isPrimary
                          ? Icon(Icons.star, color: Colors.amber)
                          : TextButton(
                            onPressed:
                                cardId.isNotEmpty
                                    ? () => _setPrimaryCard(cardId)
                                    : null,
                            child: Text(localizations.makePrimary),
                          ),
                );
              },
            ),
          Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.add_circle_outline,
              color: AppColors.primaryAccent,
            ),
            title: Text(
              localizations.bindNewCard,
              style: AppStyles.bodyText1(
                context,
              ).copyWith(color: AppColors.primaryAccent),
            ),
            onTap: _bindCardAction,
          ),
        ],
      ),
    );
  }

  Widget buildNoSubscriptionCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Container(
      decoration: AppStyles.cardDecoration(context),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            localizations.subscriptionNotActive,
            style: AppStyles.headline4(context),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _bindCardAction,
            style: AppStyles.primaryButtonStyle,
            child: Text(
              localizations.bindCard,
              style: AppStyles.bodyText1(
                context,
              ).copyWith(color: AppColors.textColorDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActiveSubscriptionCard(
    BuildContext context,
    AppLocalizations localizations,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> cards,
  ) {
    final sum = data['sum'] ?? 0;
    final dateNext =
        data['dateNextPayment'] != null
            ? DateFormat(
              'd MMMM y',
              'ru_RU',
            ).format(DateTime.parse(data['dateNextPayment']))
            : localizations.unknown;
    final primaryCard = cards.firstWhere(
      (c) => c['isPrimary'] == true,
      orElse: () => {},
    );

    return Container(
      decoration: AppStyles.cardDecoration(context),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${localizations.monthlyFee}: $sum ₸",
            style: AppStyles.headline4(context),
          ),
          const SizedBox(height: 8),
          Text(
            "${localizations.status}: ${localizations.active}",
            style: AppStyles.bodyText1(
              context,
            ).copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 8),
          Text(
            "${localizations.primaryCard}: ${primaryCard['cardMask'] ?? localizations.notAttached}",
            style: AppStyles.bodyText2(context),
          ),
          const SizedBox(height: 8),
          Text(
            "${localizations.nextCharge}: $dateNext",
            style: AppStyles.bodyText2(context),
          ),
        ],
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
        Text(
          message,
          style: AppStyles.bodyText2(context).copyWith(color: AppColors.error),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => ref.invalidate(provider),
          style: AppStyles.primaryButtonStyle,
          child: Text(
            'Обновить',
            style: AppStyles.bodyText1(
              context,
            ).copyWith(color: AppColors.textColorDark),
          ),
        ),
      ],
    );
  }
}

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
                  ref.invalidate(cardListProvider);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Карта успешно привязана'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  return NavigationDecision.prevent;
                }
                if (url.contains('error') || url.contains('fail')) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка при привязке карты'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(htmlContent));

    return Scaffold(
      appBar: AppBar(title: Text('Привязка карты')),
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
