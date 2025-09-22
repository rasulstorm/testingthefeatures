// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/features/friends/presentation/screens/friends_screen.dart';

import 'package:ISS/main.dart'; // themeModeProvider, localeProvider, localAuthServiceProvider
import 'package:ISS/features/payment/payment_screen.dart';
import 'package:ISS/services/location_service.dart'; // locationStateProvider
import 'package:permission_handler/permission_handler.dart'; // для openAppSettings
import 'package:ISS/services/picovoice_service.dart'; // голос

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
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.accountDeleted)));
        context.go('/');
      }
    }
  }

  String _getLanguageName(String langCode, AppLocalizations l) {
    switch (langCode) {
      case 'en':
        return l.languageEnglish;
      case 'ru':
        return l.languageRussian;
      case 'kk':
        return l.languageKazakh;
      default:
        return l.languageRussian;
    }
  }

  void _showLanguageSelectionDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackgroundColor(dialogContext),
          title: Text(
            l.selectLanguage,
            style: AppStyles.headline4(dialogContext),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(dialogContext, 'en', l.languageEnglish),
              _buildLanguageOption(dialogContext, 'ru', l.languageRussian),
              _buildLanguageOption(dialogContext, 'kk', l.languageKazakh),
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
      tileColor: Colors.transparent,
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

  // ======== ГЕОЛОКАЦИЯ ========

  Future<void> _toggleLocationTracking(bool isEnabled) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Нет доступа к геолокации: $e'),
          action: SnackBarAction(
            label: 'Настройки',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingRequestLocationNow = false);
    }
  }

  Widget _buildLocationSection() {
    final l = AppLocalizations.of(context);
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
              l.locationTracking,
              style: AppStyles.bodyText1(context),
            ),
            subtitle: Text(
              trackingOn ? l.enabled : l.disabled,
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
                'lat: ${lastPos.latitude.toStringAsFixed(6)}, lng: ${lastPos.longitude.toStringAsFixed(6)}',
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

  // ======== END ========

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    // состояние голоса
    final picovoiceState = ref.watch(picovoiceProvider);
    final isVoiceOn = picovoiceState != PicovoiceState.stopped;

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
                l.generalSection,
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
                      l.languageSetting,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      _getLanguageName(currentLocale.languageCode, l),
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
                    onTap: () => _showLanguageSelectionDialog(context, l),
                  ),
                  Divider(
                    color: AppColors.getBorderGrayColor(context),
                    height: 1,
                  ),
                  // Тема
                  ListTile(
                    title: Text(
                      l.themeSetting,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      themeMode == ThemeMode.light ? l.lightTheme : l.darkTheme,
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
                      l.faceIdPinSettingTitle,
                      style: AppStyles.bodyText1(context),
                    ),
                    subtitle: Text(
                      _canAuthenticate
                          ? (_isLocalAuthEnabled ? l.enabled : l.disabled)
                          : l.localAuthNotAvailable,
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

            // ----- Система -----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Система', style: AppStyles.headline3(context)),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  // Голосовое управление (микрофон)
                  ListTile(
                    title: const Text('Голосовое управление'),
                    subtitle: Text(
                      isVoiceOn
                          ? (picovoiceState ==
                                  PicovoiceState.listeningForCommand
                              ? 'Ожидает команду'
                              : 'Включено')
                          : 'Выключено',
                      style: AppStyles.bodyText2(context),
                    ),
                    leading: Icon(
                      isVoiceOn ? Icons.mic_outlined : Icons.mic_off_outlined,
                      color: AppColors.primaryAccent,
                    ),
                    trailing: Switch(
                      value: isVoiceOn,
                      onChanged:
                          (_) =>
                              ref
                                  .read(picovoiceProvider.notifier)
                                  .toggleListening(),
                    ),
                  ),
                  Divider(
                    color: AppColors.getBorderGrayColor(context),
                    height: 1,
                  ),
                  // Wi-Fi setup
                  _tile(
                    title: l.setupWifi,
                    icon: Icons.wifi_rounded,
                    onTap: () => context.push('/wifi-setup'),
                  ),
                  Divider(
                    color: AppColors.getBorderGrayColor(context),
                    height: 1,
                  ),
                  // Уведомления
                  _tile(
                    title: l.notificationsTitle,
                    icon: Icons.notifications,
                    onTap: () => context.push('/notifications'),
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

            // ======== НОВЫЙ РАЗДЕЛ: СОЦИАЛЬНЫЕ (Друзья) ========
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Социальные', style: AppStyles.headline3(context)),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  _tile(
                    title: 'Друзья',
                    icon: Icons.group_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FriendsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ----- Аккаунт -----
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                l.accountSection,
                style: AppStyles.headline3(context),
              ),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  _tile(
                    title: l.profileSetting,
                    icon: Icons.person,
                    onTap: () => context.push('/profile'),
                  ),
                  _divider(),
                  _tile(
                    title: l.familyAccess,
                    icon: Icons.group,
                    onTap: () => context.push('/family/access'),
                  ),
                  _divider(),
                  _tile(
                    title: l.paymentMethods,
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
                    title: l.changePassword,
                    icon: Icons.lock,
                    onTap: () => context.push('/change-password'),
                  ),
                  _divider(),
                  _tile(
                    title: l.deleteAccount,
                    icon: Icons.delete,
                    onTap: _confirmDeleteAccount,
                  ),
                  _divider(),
                  _tile(
                    title: l.logoutSetting,
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
                l.supportSection,
                style: AppStyles.headline3(context),
              ),
            ),
            Container(
              decoration: AppStyles.cardDecoration(context),
              child: Column(
                children: [
                  _tile(
                    title: l.helpSetting,
                    icon: Icons.help_outline,
                    onTap: () {},
                  ),
                  _divider(),
                  _tile(
                    title: l.aboutAppSetting,
                    icon: Icons.info_outline,
                    onTap: () => context.push('/about-us'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Divider _divider() => Divider(
        color: AppColors.getBorderGrayColor(context).withOpacity(0.4),
        height: 1,
        thickness: 0.7,
      );

  Widget _tile({
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
            tileColor: Colors.transparent,
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
