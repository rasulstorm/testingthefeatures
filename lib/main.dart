import 'package:ISS/features/security_control/security_objects_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/ChangePasswordScreen.dart';
import 'features/auth/otp_verification_screen.dart';
import 'features/forgot/whatsapp_code_screen.dart';
import 'features/forgot/reset_password_screen.dart';
import 'features/settings/contract.dart';
import 'appColor.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/about_us/about_us_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔕 Фоновое уведомление: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('ru_RU');

  await Future.microtask(() => setupDio());

  // Добавь эту строчку для гарантированного вывода всех логов:
  debugPrint = (String? message, {int? wrapWidth}) {
    // Здесь можно добавить кастомную логику или просто:
    if (message != null) {
      print('DEBUG: $message');
    }
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
          headlineMedium: TextStyle(color: AppColors.heading),
          headlineSmall: TextStyle(color: AppColors.heading),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF16181E),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          labelStyle: TextStyle(color: AppColors.text),
          hintStyle: TextStyle(color: AppColors.text.withOpacity(0.6)),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.primary;
            }
            return AppColors.text;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
        cardTheme: CardThemeData(
          color: AppColors.secodnBg,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: const Color(0xFFFFFFFF),
          textColor: AppColors.text,
          iconColor: AppColors.text,
        ),
        switchTheme: SwitchThemeData(
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return AppColors.primary;
            }
            return AppColors.text;
          }),
          thumbColor: MaterialStateProperty.all(Colors.white),
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/dashboard', builder: (context, state) => DashboardScreen()),
    GoRoute(path: '/settings', builder: (context, state) => SettingsScreen()),
    GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return OtpScreen(
          phone: data['phone'],
          email: data['email'],
          password: data['password'],
          iin: data['iin'],
          phoneNumber: data['phoneNumber'],
          firstName: data['firstName'],
        );
      },
    ),
    GoRoute(
      path: '/whatsapp-code',
      builder: (context, state) => const WhatsappCodeScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final phone = state.extra as String;
        return ResetPasswordScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/security-control',
      builder: (context, state) => const SecurityObjectsPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsScreen(),
    ),
     GoRoute(
      path: '/contracts', // Новый маршрут для страницы контрактов
      builder: (BuildContext context, GoRouterState state) {
        return const ContractsScreen();
      },
    ),
     GoRoute(
      path: '/about-us', // Новый маршрут
      builder: (BuildContext context, GoRouterState state) {
        return const AboutUsScreen();
      },
    ),
  ],
);
