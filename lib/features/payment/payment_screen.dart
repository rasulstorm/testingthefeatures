import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/dashboard/dashboard_screen.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dev;
import 'package:url_launcher/url_launcher.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

final cardListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) async {
    try {
      final response = await dioGetWithRefresh('/card/');
      final List data = response.data;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Error fetching card list: $e');
      rethrow;
    }
  },
);

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _updatingCardId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    ref.invalidate(subscriptionProvider);
    ref.invalidate(paymentsProvider);
    ref.invalidate(cardListProvider);
  }

  Future<void> _openTicketUrl(String? urlString) async {
    final localizations = AppLocalizations.of(context)!;
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
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _updatingCardId = cardId;
    });
    try {
      // ИСПРАВЛЕНИЕ: Используем 'CardID', как требует сервер
      await dio.post(
        '/card/setPrimaryFlag',
        queryParameters: {'CardID': cardId},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.primaryCardSetSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      _refreshAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.primaryCardSetError),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingCardId = null;
        });
      }
    }
  }

  Future<void> _bindCardAction() async {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
    try {
      final html = await fetchBindCardHtml();
      if (mounted) {
        Navigator.of(context).pop();
        final bool? success = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CardBindingWebViewPage(htmlContent: html),
          ),
        );
        if (success == true) {
          _refreshAllData();
        }
      }
    } catch (e) {
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
    final localizations = AppLocalizations.of(context)!;
    final subscriptionsAsync = ref.watch(subscriptionProvider);
    final paymentsAsync = ref.watch(paymentsProvider);
    final cardListAsync = ref.watch(cardListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.paymentAndCards),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: RefreshIndicator(
        onRefresh: _refreshAllData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.subscriptionStatus,
                style: AppStyles.headline3(context),
              ),
              const SizedBox(height: 16),
              subscriptionsAsync.when(
                data:
                    (subscriptionData) => cardListAsync.when(
                      data: (cards) {
                        final contracts = subscriptionData?['contracts'];
                        final hasSubscription =
                            contracts is List && contracts.isNotEmpty;
                        if (!hasSubscription || cards.isEmpty) {
                          return _buildNoSubscriptionCard(
                            context,
                            localizations,
                          );
                        } else {
                          return _buildActiveSubscriptionCard(
                            context,
                            localizations,
                            subscriptionData!,
                            cards,
                          );
                        }
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error:
                          (err, _) => _buildErrorWidget(
                            ref,
                            cardListProvider,
                            localizations.errorLoadingCardInfo,
                          ),
                    ),
                loading: () => Center(child: CircularProgressIndicator()),
                error:
                    (err, stack) => _buildErrorWidget(
                      ref,
                      subscriptionProvider,
                      localizations.errorLoadingSubscription,
                    ),
              ),
              const SizedBox(height: 32),
              Text(localizations.myCards, style: AppStyles.headline3(context)),
              const SizedBox(height: 16),
              cardListAsync.when(
                data: (cards) => _buildCardList(context, localizations, cards),
                loading: () => Center(child: CircularProgressIndicator()),
                error:
                    (err, _) => _buildErrorWidget(
                      ref,
                      cardListProvider,
                      localizations.errorLoadingCardInfo,
                    ),
              ),
              const SizedBox(height: 32),
              Text(
                localizations.paymentHistory,
                style: AppStyles.headline3(context),
              ),
              const SizedBox(height: 16),
              paymentsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          localizations.noPaymentRecords,
                          style: AppStyles.bodyText1(context).copyWith(
                            color: AppColors.getSecondaryTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final payment = list[index];
                      final status = payment['status'] == true;
                      final ticketUrl = payment['ticketURL'];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        color: AppColors.getCardBackgroundColor(context),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppStyles.borderRadiusAll(12),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${localizations.amount}: ${payment['amount']} ₸",
                                        style: AppStyles.bodyText1(
                                          context,
                                        ).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Icon(
                                      status ? Icons.check_circle : Icons.error,
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
                                      icon: Icon(Icons.receipt_long, size: 18),
                                      label: Text(localizations.viewReceipt),
                                      onPressed:
                                          () => _openTicketUrl(ticketUrl),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error:
                    (err, stack) => _buildErrorWidget(
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

  Widget _buildCardList(
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
                // ИСПРАВЛЕНИЕ: Используем ключ 'CardID' или 'id'
                final String cardId = card['CardID'] ?? card['id'] ?? '';

                Widget trailingWidget;
                if (_updatingCardId == cardId) {
                  trailingWidget = SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (isPrimary) {
                  trailingWidget = Icon(Icons.star, color: Colors.amber);
                } else {
                  trailingWidget = TextButton(
                    child: Text(localizations.makePrimary),
                    onPressed:
                        cardId.isNotEmpty
                            ? () => _setPrimaryCard(cardId)
                            : null,
                  );
                }

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
                  trailing: trailingWidget,
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

  Widget _buildNoSubscriptionCard(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Container(
      decoration: AppStyles.cardDecoration(context),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.subscriptionNotActive,
            style: AppStyles.headline4(context),
            textAlign: TextAlign.center,
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

  Widget _buildActiveSubscriptionCard(
    BuildContext context,
    AppLocalizations localizations,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> cards,
  ) {
    final contractsList = data['contracts'] as List<dynamic>;
    final totalSum = contractsList.fold<double>(
      0,
      (prev, element) => prev + (element['sum']?.toDouble() ?? 0),
    );
    final firstContract = contractsList.first;
    final dateNext =
        firstContract['dateNextPayment'] != null
            ? DateFormat(
              'd MMMM y',
              'ru_RU',
            ).format(DateTime.parse(firstContract['dateNextPayment']))
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
            "${localizations.monthlyFee}: ${totalSum.toStringAsFixed(0)} ₸",
            style: AppStyles.headline4(context),
          ),
          const SizedBox(height: 8),
          Text(
            "${localizations.status}: ${localizations.active}",
            style: AppStyles.bodyText1(
              context,
            ).copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
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

  Widget _buildErrorWidget(
    WidgetRef ref,
    ProviderBase provider,
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppStyles.bodyText2(
              context,
            ).copyWith(color: AppColors.error),
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
      ),
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
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Карта успешно привязана'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  return NavigationDecision.prevent;
                }
                if (url.contains('error') || url.contains('fail')) {
                  Navigator.of(context).pop(false);
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
      appBar: AppBar(
        title: Text('Привязка карты', style: AppStyles.headline3(context)),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
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
