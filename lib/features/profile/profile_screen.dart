// lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/l10n/app_localizations.dart';

// Провайдер для данных профиля, чтобы избежать повторной загрузки при перерисовке
final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  // Функция для обновления токена доступа
  Future<String> refreshAccessToken() async {
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

  final token = await refreshAccessToken();
  final response = await dio.get(
    '/user/get',
    options: Options(
      headers: {'Authorization': 'Bearer $token'},
    ), // Dio автоматически добавляет 'Bearer ', но для явности можно оставить
  );
  return response.data;
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Контроллеры для редактирования
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  // Состояния для отслеживания изменений
  bool _isDirty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();

    // Заполняем контроллеры после загрузки данных
    ref.listenManual(profileProvider, (previous, next) {
      if (next.hasValue) {
        final profile = next.value!;
        _firstNameController.text = profile['firstName'] ?? '';
        _lastNameController.text = profile['lastName'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Функция для сохранения изменений
  Future<void> _updateProfile() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_isDirty) return; // Не отправляем запрос, если ничего не изменилось

    setState(() => _isLoading = true);

    try {
      await dio.put(
        // Используем PUT-запрос, как и положено для обновления
        '/user/update',
        data: {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.profileUpdatedSuccess),
          backgroundColor: AppColors.success,
        ),
      );

      // Обновляем данные на экране
      ref.invalidate(profileProvider);
      setState(() => _isDirty = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.generalError}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Функция для показа диалога редактирования
  Future<void> _showEditDialog(
    BuildContext context,
    String title,
    TextEditingController controller,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(context),
          title: Text(title, style: AppStyles.headline4(context)),
          // СТАНЕТ:
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppStyles.bodyText1(context), // Стиль для вводимого текста
            cursorColor:
                AppColors.primaryAccent, // Цвет курсора, чтобы был виден
            decoration: InputDecoration(
              // Убираем фон у поля ввода, делая его прозрачным
              filled: false,
              // Стиль для нижней границы, когда поле не в фокусе
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.getBorderGrayColor(context),
                ),
              ),
              // Стиль для нижней границы, когда поле в фокусе
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryAccent,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                localizations.cancel,
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(context),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _isDirty = true);
                Navigator.pop(dialogContext);
              },
              style: AppStyles.primaryButtonStyle.copyWith(
                minimumSize: MaterialStateProperty.all(Size.zero),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
              child: Text(
                localizations.save,
                style: TextStyle(color: AppColors.textColorDark),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(localizations.profileSetting),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        leading: const BackButton(),
        actions: [
          // Кнопка "Сохранить" появляется только если есть изменения
          if (_isDirty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child:
                  _isLoading
                      ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                      : TextButton(
                        onPressed: _updateProfile,
                        child: Text(
                          localizations.save,
                          style: AppStyles.bodyText1(context).copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: AppStyles.cardDecoration(context),
                  child: Column(
                    children: [
                      // ИЗМЕНЕНЫ: Поля "Имя" и "Фамилия" теперь кликабельны
                      _buildEditableTile(
                        context,
                        localizations.name,
                        _firstNameController,
                        Icons.person,
                        onTap:
                            () => _showEditDialog(
                              context,
                              localizations.editName,
                              _firstNameController,
                            ),
                      ),
                      Divider(
                        color: AppColors.getBorderGrayColor(context),
                        height: 1,
                      ),
                      _buildEditableTile(
                        context,
                        localizations.lastName,
                        _lastNameController,
                        Icons.person_outline,
                        onTap:
                            () => _showEditDialog(
                              context,
                              localizations.editLastName,
                              _lastNameController,
                            ),
                      ),

                      // НЕИЗМЕННЫЕ ПОЛЯ
                      Divider(
                        color: AppColors.getBorderGrayColor(context),
                        height: 1,
                      ),
                      _buildInfoTile(
                        context,
                        localizations.email,
                        profile['email'] ?? '-',
                        Icons.email,
                      ),
                      Divider(
                        color: AppColors.getBorderGrayColor(context),
                        height: 1,
                      ),
                      _buildInfoTile(
                        context,
                        localizations.phone,
                        profile['phoneNumber'] ?? '-',
                        Icons.phone,
                      ),
                      Divider(
                        color: AppColors.getBorderGrayColor(context),
                        height: 1,
                      ),
                      _buildInfoTile(
                        context,
                        localizations.iin,
                        profile['iin'] ?? '-',
                        Icons.badge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  localizations.myContracts,
                  style: AppStyles.headline3(context),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: AppStyles.cardDecoration(context),
                  child: ListTile(
                    title: Text(
                      localizations.myContracts,
                      style: AppStyles.bodyText1(context),
                    ),
                    leading: Icon(
                      Icons.description,
                      color: AppColors.primaryAccent,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    onTap: () => context.push('/contracts'),
                  ),
                ),
              ],
            ),
          );
        },
        loading:
            () => Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            ),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '${localizations.generalError} $error',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyText1(
                      context,
                    ).copyWith(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(profileProvider),
                    style: AppStyles.primaryButtonStyle,
                    child: Text(
                      localizations.retry,
                      style: AppStyles.bodyText1(
                        context,
                      ).copyWith(color: AppColors.textColorDark),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  // Виджет для нередактируемых полей
  Widget _buildInfoTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return ListTile(
      title: Text(title, style: AppStyles.bodyText2(context)),
      subtitle: Text(
        subtitle,
        style: AppStyles.bodyText1(
          context,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
      leading: Icon(icon, color: AppColors.getSecondaryTextColor(context)),
    );
  }

  // Новый виджет для редактируемых полей
  Widget _buildEditableTile(
    BuildContext context,
    String title,
    TextEditingController controller,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: AppStyles.bodyText2(context)),
      subtitle: Text(
        controller.text,
        style: AppStyles.bodyText1(
          context,
        ).copyWith(fontWeight: FontWeight.bold),
      ),
      leading: Icon(icon, color: AppColors.getSecondaryTextColor(context)),
      trailing: Icon(
        Icons.edit,
        color: AppColors.getSecondaryTextColor(context),
        size: 20,
      ),
    );
  }
}
