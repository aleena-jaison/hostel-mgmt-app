import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/sos/providers/sos_providers.dart';

class AdminDashboard extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AdminDashboard({super.key, required this.navigationShell});

  // SOS Alerts is at index 6 in this list
  static const _navItems = <_NavItem>[
    _NavItem(icon: Icons.home, label: 'Dashboard'),
    _NavItem(icon: Icons.description, label: 'Leave Requests'),
    _NavItem(icon: Icons.qr_code, label: 'Gate Passes'),
    _NavItem(icon: Icons.people, label: 'Students'),
    _NavItem(icon: Icons.campaign, label: 'Announcements'),
    _NavItem(icon: Icons.location_on, label: 'Tracking'),
    _NavItem(icon: Icons.map, label: 'Gate Pass Map'),
    _NavItem(icon: Icons.emergency, label: 'SOS Alerts'),
    _NavItem(icon: Icons.how_to_reg, label: 'Attendance'),
    _NavItem(icon: Icons.settings, label: 'Settings'),
  ];

  static const _sosNavIndex = 7;

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeSosAlerts = ref.watch(activeSosAlertsProvider);
    final activeCount =
        activeSosAlerts.whenOrNull(data: (alerts) => alerts.length) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hostel Manager — Admin'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        actions: [
          if (activeCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.emergency, color: Colors.red, size: 18),
                label: Text(
                  '$activeCount active SOS',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => _onItemTapped(_sosNavIndex),
              ),
            ),
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
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.selected,
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
                  destinations: _navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    Widget icon = Icon(item.icon);

                    if (index == _sosNavIndex && activeCount > 0) {
                      icon = Badge(
                        label: Text('$activeCount'),
                        backgroundColor: Colors.red,
                        child: Icon(item.icon, color: Colors.red),
                      );
                    }

                    return NavigationRailDestination(
                      icon: icon,
                      selectedIcon: icon,
                      label: Text(item.label),
                    );
                  }).toList(),
                ),
              ),
            ),
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
