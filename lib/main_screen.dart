// lib/main_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/scenarios/scenarios_screen.dart';
import 'package:ISS/features/settings/settings_screen.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/features/home/home_screen.dart';
import 'package:ISS/services/firebase_messaging_service.dart';
import 'package:ISS/services/picovoice_service.dart';
import 'package:ISS/features/rooms/rooms_and_devices_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firebaseMessagingServiceProvider).init();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const RoomsAndDevicesScreen(),
    const ScenariosScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final picovoiceState = ref.watch(picovoiceProvider);

    ref.listen<PicovoiceState>(picovoiceProvider, (previous, next) {
      if (next == PicovoiceState.listeningForCommand) {
        _animationController.repeat(reverse: true);
      } else {
        if (_animationController.isAnimating) {
          _animationController.stop();
          _animationController.reset();
        }
      }
    });

    final List<String> _pageTitles = <String>[
      localizations.homeTab,
      localizations.devicesTab,
      localizations.scenariosTab,
      localizations.settingsTab,
    ];

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: AppStyles.headline3(context),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        actions: [
          IconButton(
            iconSize: 28,
            splashRadius: 24,
            icon: ScaleTransition(
              scale: _animation,
              child: Icon(
                picovoiceState == PicovoiceState.stopped
                    ? Icons.mic_off_outlined
                    : Icons.mic_outlined,
                color:
                    picovoiceState == PicovoiceState.listeningForCommand
                        ? AppColors.primaryAccent
                        : AppColors.getTextColor(context),
              ),
            ),
            onPressed: () {
              ref.read(picovoiceProvider.notifier).toggleListening();
            },
            tooltip: "Голосовое управление",
          ),
          IconButton(
            icon: Icon(
              Icons.wifi_rounded,
              color: AppColors.getTextColor(context),
            ),
            onPressed: () => context.push('/wifi-setup'),
            tooltip: localizations.setupWifi,
          ),
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: AppColors.getTextColor(context),
            ),
            onPressed: () => context.push('/notifications'),
            tooltip: localizations.notificationsTitle,
          ),
          IconButton(
            icon: Icon(Icons.person, color: AppColors.getTextColor(context)),
            onPressed: () => context.push('/profile'),
            tooltip: localizations.profileIcon,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: localizations.homeTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.devices_other_outlined),
            activeIcon: const Icon(Icons.devices_other),
            label: localizations.devicesTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.playlist_add_check_outlined),
            activeIcon: const Icon(Icons.playlist_add_check),
            label: localizations.scenariosTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: localizations.settingsTab,
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
