import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hostel_manager/features/auth/providers/auth_providers.dart';

class AdminDashboard extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminDashboard({super.key, required this.navigationShell});

  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.home, label: 'Dashboard'),
    _NavItem(icon: Icons.description, label: 'Leave Requests'),
    _NavItem(icon: Icons.qr_code, label: 'Gate Passes'),
    _NavItem(icon: Icons.people, label: 'Students'),
    _NavItem(icon: Icons.campaign, label: 'Announcements'),
    _NavItem(icon: Icons.location_on, label: 'Tracking'),
    _NavItem(icon: Icons.how_to_reg, label: 'Attendance'),
    _NavItem(icon: Icons.settings, label: 'Settings'),
  ];

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Manager — Admin'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            backgroundColor: colorScheme.surfaceContainerLow,
            indicatorColor: colorScheme.secondaryContainer,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Icon(
                Icons.apartment,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            destinations: _navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
