import 'package:ISS/features/main_menu_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];

    if (newAccessToken == null || newRefreshToken == null) {
      throw Exception("Неверный ответ при обновлении токена");
    }

    await prefs.setString('accessToken', newAccessToken);
    await prefs.setString('refreshToken', newRefreshToken);

    return newAccessToken;
  }

  Future<Map<String, dynamic>> _fetchProfile() async {
    final token = await _refreshAccessToken();

    final response = await dio.get(
      '/user/get',
      options: Options(headers: {'Authorization': '$token'}),
    );
    return response.data;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> _deleteAccount() async {
      try {
        final token = await _refreshAccessToken();

        await dio.delete(
          '/user/delete',
          options: Options(headers: {'Authorization': '$token'}),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('accessToken');
        await prefs.remove('refreshToken');
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Аккаунт удалён')));
          context.go('/');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка при удалении аккаунта')),
          );
        }
      }
    }

    Future<void> _confirmDeleteAccount() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              contentTextStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              title: const Text('Подтвердите удаление'),
              content: const Text(
                'Вы уверены, что хотите удалить аккаунт? Это действие необратимо.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Удалить',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        await _deleteAccount();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки и профиль'),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final profile = snapshot.data!;
          final contracts = profile['contracts'];
          final contract =
              (contracts is List && contracts.isNotEmpty) ? contracts[0] : {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTile('Имя', profile['firstName'] ?? '-', Icons.person),
                _buildTile('Email', profile['email'] ?? '-', Icons.email),
                _buildTile(
                  'Телефон',
                  profile['phoneNumber'] ?? '-',
                  Icons.phone,
                ),
                _buildTile('ИИН', profile['iin'] ?? '-', Icons.badge),
                _buildTile(
                  'Номер договора',
                  contract['contractNumber'] ?? '-',
                  Icons.description,
                ),
                _buildTile(
                  'Абонентская плата',
                  '${contract['sum'] ?? 0} ₸',
                  Icons.payments,
                ),
                Divider(color: AppColors.text),
                _buildTile(
                  'Изменить пароль',
                  '',
                  Icons.lock,
                  onTap: () => context.push('/change-password'),
                ),
                Divider(color: AppColors.text),
                _buildTile(
                  'Удалить аккаунт',
                  '',
                  Icons.delete,
                  onTap: _confirmDeleteAccount,
                ),
                Divider(color: AppColors.text),
                ListTile(
                  title: const Text(
                    'Выйти из аккаунта',
                    style: TextStyle(color: Colors.red),
                  ),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('accessToken');
                    await prefs.remove('refreshToken');
                    context.go('/');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(
    String title,
    String subtitle,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          tileColor: AppColors.secodnBg,
          title: Text(title),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          leading: Icon(icon),
          onTap: onTap,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
