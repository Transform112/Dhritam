import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

import 'home_screen.dart';
import '../insights/insights_screen.dart';
import '../profile/profile_screen.dart';

// THE MISSING IMPORTS BASED ON YOUR DIRECTORY
import '../devices/devices_screen.dart'; 
import '../train/train_screen.dart'; 

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // UPDATED: All 5 screens are now in the stack!
  final List<Widget> _screens = const [
    HomeScreen(),
    DevicesScreen(), // Tab 1: Bluetooth Connection
    TrainScreen(),   // Tab 2: Alpha Drift Game
    InsightsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
        indicatorColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: AppTheme.primaryPurple),
            label: 'Home',
          ),
          // NEW: Devices Tab
          NavigationDestination(
            icon: Icon(Icons.bluetooth_connected_outlined),
            selectedIcon: Icon(Icons.bluetooth_connected_rounded, color: AppTheme.primaryPurple),
            label: 'Devices',
          ),
          // NEW: Alpha Drift / Train Tab
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded, color: AppTheme.primaryPurple),
            label: 'Train',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded, color: AppTheme.primaryPurple),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryPurple),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}