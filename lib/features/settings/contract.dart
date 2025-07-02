import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/appColor.dart';
import 'package:intl/intl.dart'; 

final contractsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
    '/user/contracts',
    options: Options(headers: {'Authorization': '$newAccessToken'}),
  );
  
  if (response.data is List) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsyncValue = ref.watch(contractsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои контракты'),
      ),
      body: contractsAsyncValue.when(
        data: (contracts) {
          if (contracts.isEmpty) {
            return const Center(
              child: Text(
                'У вас пока нет активных контрактов.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final contract = contracts[index];
              final dateNextPayment = contract['dateNextPayment'] != null
                  ? DateFormat('d MMMM y', 'ru_RU').format(DateTime.parse(contract['dateNextPayment']))
                  : 'неизвестно';

              return Card(
                color: AppColors.secodnBg,
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Контракт: ${contract['contractNumber'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Сумма: ${contract['sum'] ?? 0} ₸',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Следующая оплата: $dateNextPayment',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      // Здесь можно добавить больше полей контракта, если необходимо
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ошибка загрузки контрактов: ${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => ref.invalidate(contractsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}