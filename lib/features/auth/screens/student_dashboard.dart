import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/gate_pass/widgets/gate_pass_location_tracker.dart';
import 'package:hostel_manager/features/sos/models/sos_alert.dart';
import 'package:hostel_manager/features/sos/providers/sos_providers.dart';

class StudentDashboard extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const StudentDashboard({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return GatePassLocationTracker(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hostel Manager'),
          actions: [
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: currentUser?.profileImageUrl != null
                      ? NetworkImage(currentUser!.profileImageUrl!)
                      : null,
                  child: currentUser?.profileImageUrl == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
              ),
            ),
          ],
        ),
        body: navigationShell,
        floatingActionButton: navigationShell.currentIndex == 1
            ? null
            : const _SpeedDialFab(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Leave',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_2_outlined),
              selectedIcon: Icon(Icons.qr_code_2),
              label: 'Gate Pass',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign),
              label: 'Announcements',
            ),
            NavigationDestination(
              icon: Icon(Icons.how_to_reg_outlined),
              selectedIcon: Icon(Icons.how_to_reg),
              label: 'Attendance',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Speed Dial FAB
// ---------------------------------------------------------------------------

class _SpeedDialFab extends ConsumerStatefulWidget {
  const _SpeedDialFab();

  @override
  ConsumerState<_SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends ConsumerState<_SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  bool _sendingSos = false;
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) _toggle();
  }

  Future<void> _triggerSos() async {
    _close();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emergency, color: Colors.red, size: 48),
        title: const Text('Send SOS Alert?'),
        content: const Text(
          'This will send an emergency Level 1 alert to the warden immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sendingSos = true);

    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) return;

      final alert = SosAlert(
        id: '',
        studentId: currentUser.id,
        studentName: currentUser.name,
        roomNumber: currentUser.roomNumber,
        level: 1,
        status: 'active',
        createdAt: DateTime.now(),
      );

      final sosService = ref.read(sosServiceProvider);
      await sosService.sendSosAlert(alert);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS alert sent to warden!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingSos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Scrim to close on outside tap
        if (_isOpen)
          GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),

        // Mini FABs
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // SOS
            _MiniAction(
              animation: _expandAnimation,
              index: 2,
              label: 'SOS',
              icon: Icons.emergency,
              color: Colors.red,
              onTap: _sendingSos ? null : _triggerSos,
            ),
            const SizedBox(height: 12),

            // Apply Leave
            _MiniAction(
              animation: _expandAnimation,
              index: 1,
              label: 'Apply Leave',
              icon: Icons.description,
              color: Colors.blue,
              onTap: () {
                _close();
                context.push('/apply-leave');
              },
            ),
            const SizedBox(height: 12),

            // Request Gate Pass
            _MiniAction(
              animation: _expandAnimation,
              index: 0,
              label: 'Gate Pass',
              icon: Icons.qr_code_2,
              color: Colors.green,
              onTap: () {
                _close();
                context.go('/student/gate');
              },
            ),
            const SizedBox(height: 16),

            // Main FAB
            FloatingActionButton(
              heroTag: 'speed_dial_main',
              onPressed: _toggle,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MiniAction({
    required this.animation,
    required this.index,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        alignment: Alignment.bottomRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: FloatingActionButton(
                heroTag: 'speed_dial_$index',
                backgroundColor: color,
                onPressed: onTap,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
