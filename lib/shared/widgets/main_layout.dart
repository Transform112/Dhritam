import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import the 5 feature screens
import '../../features/home/home_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/train/train_screen.dart';
import '../../features/devices/devices_screen.dart';
import '../../features/profile/profile_screen.dart';

// Upgraded Riverpod provider to track the active tab index
final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(() {
  return BottomNavIndexNotifier();
});

class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // IndexedStack keeps all tabs alive in memory, preventing the UI thread 
    // from rebuilding complex charts when the user switches tabs.
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          InsightsScreen(),
          TrainScreen(),
          DevicesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
          height: 64, // PRD minimum height
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => ref.read(bottomNavIndexProvider.notifier).setIndex(index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Insights'),
              BottomNavigationBarItem(icon: Icon(Icons.self_improvement_outlined), activeIcon: Icon(Icons.self_improvement), label: 'Train'),
              BottomNavigationBarItem(icon: Icon(Icons.bluetooth_connected_outlined), activeIcon: Icon(Icons.bluetooth_connected), label: 'Devices'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}