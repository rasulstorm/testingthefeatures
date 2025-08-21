// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';

import 'package:ISS/main.dart'; // themeModeProvider, localeProvider, localAuthServiceProvider
import 'package:ISS/features/payment/payment_screen.dart';
import 'package:ISS/services/location_service.dart'; // locationStateProvider
import 'package:permission_handler/permission_handler.dart'; // для openAppSettings

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLocalAuthEnabled = false;
  bool _canAuthenticate = false;

  // локальные флаги для UI (остальное берём из locationStateProvider)
  bool _loadingRequestLocationNow = false;

  @override
  void initState() {
    super.initState();
    _loadInitialStatuses();
  }

  Future<void> _loadInitialStatuses() async {
    final localAuthService = ref.read(localAuthServiceProvider);
    final localAuthEnabled = await localAuthService.isLocalAuthEnabled();
    final canAuth = await localAuthService.canAuthenticate();

    if (!mounted) return;
    setState(() {
      _isLocalAuthEnabled = localAuthEnabled;
      _canAuthenticate = canAuth;
    });

    // стейт локации сам подтянется из locationStateProvider (он восстанавливает флаг из SharedPreferences)
  }

  Future<void> _toggleTheme(bool dark) async {
    await ref
        .read(themeModeProvider.notifier)
        .toggleTheme(dark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _toggleLocalAuth(bool enable) async {
    final localizations = AppLocalizations.of(context);
    final localAuthService = ref.read(localAuthServiceProvider);

    if (enable) {
      final ok = await localAuthService.authenticate();
      if (ok) {
        await localAuthService.setLocalAuthEnabled(true);
        if (mounted) {
          setState(() => _isLocalAuthEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.localAuthEnabledMessage)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.localAuthNotEnabledMessage)),
          );
        }
      }
    } else {
      await localAuthService.setLocalAuthEnabled(false);
      if (mounted) {
        setState(() => _isLocalAuthEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.localAuthDisabledMessage)),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            titleTextStyle: AppStyles.headline4(context),
            contentTextStyle: AppStyles.bodyText1(
              context,
            ).copyWith(color: AppColors.getSecondaryTextColor(context)),
            title: Text(localizations.logoutConfirmationTitle),
            content: Text(localizations.logoutConfirmationMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: AppStyles.textButtonStyle(context),
                child: Text(
                  localizations.cancel,
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: AppColors.primaryAccent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: AppStyles.textButtonStyle(context),
                child: Text(
                  localizations.logoutSetting,
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await ref.read(localAuthServiceProvider).setLocalAuthEnabled(false);
      if (context.mounted) {
        context.go('/');
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            titleTextStyle: AppStyles.headline4(context),
            contentTextStyle: AppStyles.bodyText1(
              context,
            ).copyWith(color: AppColors.getSecondaryTextColor(context)),
            title: Text(localizations.deleteConfirmationTitle),
            content: Text(localizations.deleteConfirmationMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: AppStyles.textButtonStyle(context),
                child: Text(
                  localizations.cancel,
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: AppColors.primaryAccent),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: AppStyles.textButtonStyle(context),
                child: Text(
                  localizations.delete,
                  style: AppStyles.bodyText1(
                    context,
                  ).copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      // твой текущий delete-аккаунт-алгоритм можно оставить/вынести в сервис.
      // Чтобы не раздувать ответ, опущу. Используй свою реализацию.
      // Здесь просто заглушка:
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.accountDeleted)));
        context.go('/');
      }
    }
  }

  String _getLanguageName(String langCode, AppLocalizations localizations) {
    switch (langCode) {
      case 'en':
        return localizations.languageEnglish;
      case 'ru':
        return localizations.languageRussian;
      case 'kk':
        return localizations.languageKazakh;
      default:
        return localizations.languageRussian;
    }
  }

  void _showLanguageSelectionDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(dialogContext),
          title: Text(
            localizations.selectLanguage,
            style: AppStyles.headline4(dialogContext),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                dialogContext,
                'en',
                localizations.languageEnglish,
              ),
              _buildLanguageOption(
                dialogContext,
                'ru',
                localizations.languageRussian,
              ),
              _buildLanguageOption(
                dialogContext,
                'kk',
                localizations.languageKazakh,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext ctx,
    String langCode,
    String langName,
  ) {
    final currentLocale = ref.watch(localeProvider);
    final selected = currentLocale.languageCode == langCode;
    return ListTile(
      tileColor: AppColors.getCardBackgroundColor(ctx),
      title: Text(
        langName,
        style: AppStyles.bodyText1(ctx).copyWith(
          color:
              selected ? AppColors.primaryAccent : AppColors.getTextColor(ctx),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          selected ? Icon(Icons.check, color: AppColors.primaryAccent) : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(langCode));
        Navigator.pop(ctx);
      },
    );
  }

  // ======== БЛОК ГЕОЛОКАЦИИ (НОВЫЙ) ========

  Future<void> _toggleLocationTracking(bool isEnabled) async {
    // Переключатель фоновой локации: просто дергаем провайдер — он сам сохранит флаг и запустит/остановит background_fetch.
    await ref
        .read(locationStateProvider.notifier)
        .setLocationTrackingEnabled(isEnabled);
  }

  Future<void> _requestPermissionAndSendOnce() async {
    setState(() => _loadingRequestLocationNow = true);
    try {
      await ref.read(locationStateProvider.notifier).requestPermissionAndSend();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Геолокация отправлена.')));
    } catch (e) {
      if (!mounted) return;
      // Покажем понятное сообщение и кнопку «Открыть настройки»
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нет доступа к геолокации: $e'),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingRequestLocationNow = false);
    }
  }

  Widget _buildLocationSection() {
    final localizations = AppLocalizations.of(context);
    final locationState = ref.watch(locationStateProvider);

    final trackingOn = locationState.trackingEnabled;
    final lastPos = locationState.lastPosition;
    final lastError = locationState.lastError;

    return Container(
      decoration: AppStyles.cardDecoration(context),
      child: Column(
        children: [
          ListTile(
            title: Text(
              localizations.locationTracking,
              style: AppStyles.bodyText1(context),
            ),
            subtitle: Text(
              trackingOn ? localizations.enabled : localizations.disabled,
              style: AppStyles.bodyText2(context),
            ),
            leading: Icon(
              Icons.location_on_outlined,
              color: AppColors.primaryAccent,
            ),
            trailing: Switch(
              value: trackingOn,
              onChanged: _toggleLocationTracking,
            ),
          ),
          Divider(color: AppColors.getBorderGrayColor(context), height: 1),
          ListTile(
            title: Text(
              'Отправить геолокацию сейчас',
              style: AppStyles.bodyText1(context),
            ),
            subtitle: Text(
              'Запросить доступ (если не выдан) и отправить одну точку',
              style: AppStyles.bodyText2(context),
            ),
            leading:
                _loadingRequestLocationNow
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryAccent,
                      ),
                    )
                    : Icon(
                      Icons.my_location_outlined,
                      color: AppColors.primaryAccent,
                    ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.getSecondaryTextColor(context),
            ),
            onTap:
                _loadingRequestLocationNow
                    ? null
                    : _requestPermissionAndSendOnce,
          ),
          if (lastPos != null || (lastError != null && lastError.isNotEmpty))
            Divider(color: AppColors.getBorderGrayColor(context), height: 1),
          if (lastPos != null)
            ListTile(
              title: Text(
                'Последняя позиция',
                style: AppStyles.bodyText1(context),
              ),
              subtitle: Text(
                'lat: ${lastPos.latitude.toStringAsFixed(6)}, '
                'lng: ${lastPos.longitude.toStringAsFixed(6)}',
                style: AppStyles.bodyText2(context),
              ),
              leading: Icon(
                Icons.place_outlined,
                color: AppColors.primaryAccent,
              ),
            ),
          if (lastError != null && lastError.isNotEmpty)
            ListTile(
              title: Text(
                'Последняя ошибка геолокации',
                style: AppStyles.bodyText1(context),
              ),
              subtitle: Text(
                lastError,
                style: AppStyles.bodyText2(
                  context,
                ).copyWith(color: AppColors.error),
              ),
              leading: Icon(Icons.error_outline, color: AppColors.error),
              trailing: TextButton(
                onPressed: openAppSettings,
                child: const Text('Настройки'),
              ),
            ),
        ],
      ),
    );
  }

  // ======== END БЛОК ГЕОЛОКАЦИИ ========

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Общие -----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                localizations.generalSection,
                style: AppStyles.headline3(context),
              ),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  // Язык
                  ListTile(
                    title: Text(
                      localizations.languageSetting,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      _getLanguageName(
                        currentLocale.languageCode,
                        localizations,
                      ),
                      style: AppStyles.bodyText2(context),
                    ),
                    leading: Icon(
                      Icons.language,
                      color: AppColors.primaryAccent,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.getSecondaryTextColor(context),
                    ),
                    onTap:
                        () => _showLanguageSelectionDialog(
                          context,
                          localizations,
                        ),
                  ),
                  Divider(
                    color: AppColors.getBorderGrayColor(context),
                    height: 1,
                  ),
                  // Тема
                  ListTile(
                    title: Text(
                      localizations.themeSetting,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      themeMode == ThemeMode.light
                          ? localizations.lightTheme
                          : localizations.darkTheme,
                      style: AppStyles.bodyText2(context),
                    ),
                    leading: Icon(
                      Icons.brightness_2,
                      color: AppColors.primaryAccent,
                    ),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (v) => _toggleTheme(v),
                    ),
                  ),
                  Divider(
                    color: AppColors.getBorderGrayColor(context),
                    height: 1,
                  ),
                  // Биометрия
                  ListTile(
                    title: Text(
                      localizations.faceIdPinSettingTitle,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      _canAuthenticate
                          ? (_isLocalAuthEnabled
                              ? localizations.enabled
                              : localizations.disabled)
                          : localizations.localAuthNotAvailable,
                      style: AppStyles.bodyText2(context),
                    ),
                    leading: Icon(
                      Icons.fingerprint,
                      color: AppColors.primaryAccent,
                    ),
                    trailing: Switch(
                      value: _isLocalAuthEnabled,
                      onChanged:
                          _canAuthenticate ? (v) => _toggleLocalAuth(v) : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ----- Геолокация -----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Геолокация', style: AppStyles.headline3(context)),
            ),
            _buildLocationSection(),

            const SizedBox(height: 20),

            // ----- Аккаунт -----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                localizations.accountSection,
                style: AppStyles.headline3(context),
              ),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  _tile(
                    title: localizations.profileSetting,
                    icon: Icons.person,
                    onTap: () => context.push('/profile'),
                  ),
                  _divider(),
                  _tile(
                    title: localizations.familyAccess,
                    icon: Icons.group,
                    onTap: () => context.push('/family-groups'),
                  ),
                  _divider(),
                  _tile(
                    title: localizations.paymentMethods,
                    icon: Icons.payment,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentScreen(),
                        ),
                      );
                    },
                  ),
                  _divider(),
                  _tile(
                    title: localizations.changePassword,
                    icon: Icons.lock,
                    onTap: () => context.push('/change-password'),
                  ),
                  _divider(),
                  _tile(
                    title: localizations.deleteAccount,
                    icon: Icons.delete,
                    onTap: _confirmDeleteAccount,
                  ),
                  _divider(),
                  _tile(
                    title: localizations.logoutSetting,
                    icon: Icons.logout,
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ----- Поддержка -----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                localizations.supportSection,
                style: AppStyles.headline3(context),
              ),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  _tile(
                    title: localizations.helpSetting,
                    icon: Icons.help_outline,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: localizations.aboutAppSetting,
                    icon: Icons.info_outline,
                    onTap: () => context.push('/about-us'),
                  ),
                  _divider(),
                  _tile(
                    title: "Голосовое управление",
                    icon: Icons.mic,
                    onTap: () => context.push('/voice-control'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Divider _divider() =>
      Divider(color: AppColors.getBorderGrayColor(context), height: 1);

  Widget _tile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      tileColor: AppColors.getCardBackgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppStyles.borderRadiusAll(12),
      ),
      title: Text(title, style: AppStyles.bodyText1(context)),
      leading: Icon(icon, color: AppColors.primaryAccent),
      trailing:
          onTap != null
              ? Icon(
                Icons.chevron_right,
                color: AppColors.getSecondaryTextColor(context),
              )
              : null,
      onTap: onTap,
    );
  }
}
