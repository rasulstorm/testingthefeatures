// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ISS/appColor.dart';
// import 'package:ISS/appstyles.dart'; // не используется здесь
import 'package:ISS/features/scenarios/presentation/screens/scenarios_screen.dart';
import 'package:ISS/features/settings/settings_screen.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/features/home/home_screen.dart';
import 'package:ISS/services/firebase_messaging_service.dart';

// НОВОЕ: таб с камерами
import 'package:ISS/features/camera/presentation/screens/camera_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseMessagingServiceProvider).init();
    });
  }

  // 4 страницы: Home, Scenarios, Cameras, Settings
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const ScenariosScreen(),
    const CamerasScreen(), // <-- новый таб
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),

      // Без AppBar
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),

      // Нижняя навигация
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: t.homeTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.playlist_add_check_outlined),
            activeIcon: const Icon(Icons.playlist_add_check),
            label: t.scenariosTab, // раньше было devicesTab, теперь корректно
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.videocam_outlined),
            activeIcon: const Icon(Icons.videocam),
            label: 'Камеры', // при желании добавь в локализации cameraTab
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: t.settingsTab,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.getLightGreyColor(context),
        backgroundColor: AppColors.getCardBackgroundColor(context),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}
