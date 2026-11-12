import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/pages/alerts_list_screen.dart';
import 'package:avicoleguard_mobile/features/alerts/presentation/providers/alert_provider.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/pages/assistance_list_screen.dart';
import 'package:avicoleguard_mobile/features/assistance/presentation/providers/assistance_provider.dart';
import 'package:avicoleguard_mobile/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:avicoleguard_mobile/features/flocks/presentation/pages/flocks_list_screen.dart';
import 'package:avicoleguard_mobile/features/profile/presentation/pages/profile_sync_screen.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = '/home';
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    FlocksListScreen(),
    AlertsListScreen(),
    AssistanceListScreen(),
    ProfileSyncScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final openAlertsCount = context.watch<AlertProvider>().openAlertsCount;
    final openTicketsCount = context.watch<AssistanceProvider>().openTicketsCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primary.withAlpha(40),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Accueil',
            ),
            const NavigationDestination(
              icon: Icon(Icons.egg_alt_outlined),
              selectedIcon: Icon(Icons.egg_alt, color: AppColors.primary),
              label: 'Lots',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: openAlertsCount > 0,
                label: Text('$openAlertsCount'),
                child: const Icon(Icons.notifications_active_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: openAlertsCount > 0,
                label: Text('$openAlertsCount'),
                child: const Icon(Icons.notifications_active,
                    color: AppColors.primary),
              ),
              label: 'Alertes',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: openTicketsCount > 0,
                label: Text('$openTicketsCount'),
                child: const Icon(Icons.support_agent_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: openTicketsCount > 0,
                label: Text('$openTicketsCount'),
                child: const Icon(Icons.support_agent,
                    color: AppColors.primary),
              ),
              label: 'Assistance',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
