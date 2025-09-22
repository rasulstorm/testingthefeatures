import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:ISS/services/location_service.dart' as loc;
import 'package:ISS/main_screen.dart';
import 'package:ISS/initial_loading_screen.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/onboarding_screen.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/voice/voice_control_screen.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/features/family/group_list_screen.dart';
import 'package:ISS/features/family/group_create_screen.dart';
import 'package:ISS/features/family/group_manage_screen.dart';
import 'package:ISS/features/family/family_access_screen.dart';
import 'package:ISS/core/network/auth_service.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/services/local_auth_service.dart';
import 'package:ISS/services/pin_code_service.dart';
import 'package:ISS/services/firebase_messaging_service.dart';
import 'package:ISS/services/permission_service.dart';
import 'package:ISS/features/auth/login_screen.dart';
import 'package:ISS/features/auth/register_screen.dart';
import 'package:ISS/features/auth/ChangePasswordScreen.dart';
import 'package:ISS/features/auth/otp_verification_screen.dart';
import 'package:ISS/features/auth/pin_code_screen.dart';
import 'package:ISS/features/forgot/whatsapp_code_screen.dart';
import 'package:ISS/features/forgot/reset_password_screen.dart';
import 'package:ISS/features/profile/profile_screen.dart';
import 'package:ISS/features/settings/settings_screen.dart';
import 'package:ISS/features/settings/contract.dart';
import 'package:ISS/features/about_us/about_us_screen.dart';
import 'package:ISS/features/notifications/notifications_provider.dart';
import 'package:ISS/features/scenarios/presentation/screens/scenarios_screen.dart';
import 'package:ISS/features/wifi_setup/wifi_setup_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ISS/features/ai_chat/ai_chat_screen.dart';
import 'package:ISS/features/home_map/presentation/home_map_screen.dart';
import 'package:ISS/features/friends/presentation/screens/friends_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final authServiceProvider = Provider((ref) => AuthService());
final pinCodeServiceProvider = Provider((ref) => PinCodeService());
final localAuthServiceProvider = Provider(
  (ref) => LocalAuthService(
    ref.read(authServiceProvider),
    ref.read(pinCodeServiceProvider),
  ),
);
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool("onboarding_seen") ?? false;
    if (!seen) {
      state =
          ThemeMode.light; // по умолчанию светлая тема для новых пользователей
      return;
    }
    final themeIndex = prefs.getInt('themeMode');
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    state = mode;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ru')) {
    _loadLocale();
  }
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode');
    if (langCode != null) {
      state = Locale(langCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    state = locale;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv: .env not found, running with defaults. $e");
  }
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('ru_RU');

  final authServiceInstance = AuthService();
  setupDioInterceptors(authServiceInstance);

  // headless-таск background_fetch
  try {
    BackgroundFetch.registerHeadlessTask(loc.backgroundFetchHeadlessTask);
  } catch (e) {
    // ignore: avoid_print
    print("BackgroundFetch.registerHeadlessTask error: $e");
  }

  // Автовосстановление фонового трекинга, если включен
  try {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isLocationTrackingEnabled') ?? false;
    if (isEnabled) {
      await loc.LocationStateNotifier().setLocationTrackingEnabled(true);
    }
  } catch (e) {
    // ignore: avoid_print
    print("Restore background location tracking failed: $e");
  }

  // Запрос всех разрешений «как с уведомлениями» — после первого кадра UI
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PermissionService.requestAllOnce();
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final card =
        isDark ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight;
    final text = isDark ? AppColors.textColorDark : AppColors.textColorLight;
    final secondaryText =
        isDark
            ? AppColors.secondaryTextColorDark
            : AppColors.secondaryTextColorLight;
    final border =
        isDark ? AppColors.borderGrayDark : AppColors.borderGrayLight;
    final hint = isDark ? AppColors.lightGreyDark : AppColors.lightGreyLight;

    return ThemeData(
      brightness: brightness,
      primaryColor: AppColors.primaryAccent,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: text),
        bodyMedium: TextStyle(fontSize: 14, color: secondaryText),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: text,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppStyles.primaryButtonStyle.copyWith(
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 50)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAccent,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: AppStyles.borderRadiusAll(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: AppStyles.borderRadiusAll(8),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryAccent, width: 2),
        ),
        labelStyle: TextStyle(fontSize: 16, color: secondaryText),
        hintStyle: TextStyle(fontSize: 14, color: hint),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return hint;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textColorDark),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadiusAll(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: card,
        textColor: text,
        iconColor: secondaryText,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryAccent;
          }
          return hint;
        }),
        thumbColor: WidgetStateProperty.all(AppColors.textColorDark),
      ),
      popupMenuTheme: PopupMenuThemeData(color: card),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: card),
      dialogTheme: DialogThemeData(backgroundColor: card),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: themeMode,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

// --- GoRouter ---
final GoRouter _router = GoRouter(
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const InitialLoadingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/contracts',
      builder: (context, state) => const ContractsScreen(),
    ),
    GoRoute(
      path: '/about-us',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsScreen(),
    ),
    GoRoute(
      path: '/voice-control',
      builder: (context, state) => const VoiceControlScreen(),
    ),
    GoRoute(
      path: '/home/map',
      builder: (context, state) => const HomeMapScreen(),
    ),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendsScreen(),
    ),
    GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
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
          lastName: data['lastName'],
        );
      },
    ),
    GoRoute(
      path: '/whatsapp-code',
      builder: (context, state) => const WhatsappCodeScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder:
          (context, state) => ResetPasswordScreen(phone: state.extra as String),
    ),
    GoRoute(
      path: '/pin_code',
      builder: (context, state) {
        final Map<String, dynamic> args = state.extra as Map<String, dynamic>;
        return PinCodeScreen(
          mode: args['mode'] as PinCodeMode,
          initialPin: args['initialPin'] as String?,
          onPinVerified: args['onPinVerified'] as VoidCallback?,
          onPinSet: args['onPinSet'] as VoidCallback?,
          onAuthFailed: args['onAuthFailed'] as VoidCallback?,
        );
      },
    ),

    // Сценарии
    GoRoute(
      path: '/scenarios',
      builder: (context, state) => const ScenariosScreen(),
    ),
    GoRoute(path: '/scenarios', builder: (c, s) => const ScenariosScreen()),
    // Настройка Хаба
    GoRoute(
      path: '/wifi-setup',
      builder: (context, state) => const WifiSetupScreen(),
    ),
    // Комнаты
    GoRoute(
      path: '/family/access',
      builder: (context, state) => const FamilyAccessScreen(),
    ),
    GoRoute(
      path: '/family/list',
      builder: (context, state) => const GroupListScreen(),
    ),
    GoRoute(
      path: '/family/create',
      builder: (context, state) => const GroupCreateScreen(),
    ),
    GoRoute(
      path: '/family/manage',
      builder: (context, state) {
        final extra = (state.extra ?? const {}) as Map<String, dynamic>;
        return GroupManageScreen(
          groupId: extra['groupId'] as String,
          name: extra['name'] as String? ?? '',
        );
      },
    ),
  ],
);

// Удобные расширения (как у тебя было)
extension OtpScreenFromExtra on OtpScreen {
  static OtpScreen fromExtra(Object? extra) {
    final data = extra as Map<String, dynamic>;
    return OtpScreen(
      phone: data['phone'],
      email: data['email'],
      password: data['password'],
      iin: data['iin'],
      phoneNumber: data['phoneNumber'],
      firstName: data['firstName'],
      lastName: data['lastName'],
    );
  }
}

extension PinCodeScreenFromExtra on PinCodeScreen {
  static PinCodeScreen fromExtra(Object? extra) {
    final args = extra as Map<String, dynamic>;
    return PinCodeScreen(
      mode: args['mode'] as PinCodeMode,
      initialPin: args['initialPin'] as String?,
      onPinVerified: args['onPinVerified'] as VoidCallback?,
      onPinSet: args['onPinSet'] as VoidCallback?,
      onAuthFailed: args['onAuthFailed'] as VoidCallback?,
    );
  }
}
