import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../home/presentation/screens/home_screen.dart';
import '../../staff/presentation/screens/staff_screen.dart';

/// Root of the app: bottom navigation between Home and Staff.
///
/// Uses an [IndexedStack] so each tab keeps its state, such as the day
/// selected in the Staff tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), StaffScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: AppStrings.staff,
          ),
        ],
      ),
    );
  }
}
