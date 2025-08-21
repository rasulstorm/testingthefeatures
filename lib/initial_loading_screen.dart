// lib/initial_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/main.dart'; // для провайдеров authServiceProvider/localAuthServiceProvider

class InitialLoadingScreen extends ConsumerStatefulWidget {
  const InitialLoadingScreen({super.key});

  @override
  ConsumerState<InitialLoadingScreen> createState() =>
      _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends ConsumerState<InitialLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // небольшая задержка, чтобы отрисовался сплэш/лоадер
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final localizations = AppLocalizations.of(context);
    final localAuthService = ref.read(localAuthServiceProvider);
    final authService = ref.read(authServiceProvider);

    final String? accessToken = await authService.getAccessToken();

    // нет токена — на логин
    if (accessToken == null || accessToken.isEmpty) {
      if (mounted) context.go('/login');
      return;
    }

    // если включена локальная аутентификация (FaceID/TouchID), проверяем её
    final bool isLocalAuthEnabledByUser =
        await localAuthService.isLocalAuthEnabled();

    if (isLocalAuthEnabledByUser) {
      final bool authenticated = await localAuthService.authenticate();
      if (authenticated) {
        final bool tokenValid = await localAuthService.checkAndRefreshToken();
        if (mounted) {
          if (tokenValid) {
            context.go('/main');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(localizations.sessionExpiredLoginAgain)),
            );
            context.go('/login');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.localAuthFailedLoginWithCredentials),
            ),
          );
          context.go('/login');
        }
      }
    } else {
      final bool tokenValid = await localAuthService.checkAndRefreshToken();
      if (mounted) {
        if (tokenValid) {
          context.go('/main');
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(localizations.sessionExpired)));
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              localizations.loadingApp,
              style:
                  Theme.of(context).textTheme.bodyLarge ??
                  const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
