import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/auth/screens/login_screen.dart';
import 'package:hostel_manager/features/auth/screens/student_dashboard.dart';
import 'package:hostel_manager/features/admin/screens/admin_dashboard.dart';
import 'package:hostel_manager/features/admin/screens/admin_home_screen.dart';
import 'package:hostel_manager/features/admin/screens/settings_screen.dart';
import 'package:hostel_manager/features/admin/screens/student_roster.dart';
import 'package:hostel_manager/features/leave/screens/leave_list_screen.dart';

import 'package:hostel_manager/features/leave/screens/leave_manage_screen.dart';
import 'package:hostel_manager/features/gate_pass/screens/gate_pass_screen.dart';
import 'package:hostel_manager/features/gate_pass/screens/gate_pass_manage_screen.dart';

import 'package:hostel_manager/features/announcements/screens/announcement_feed.dart';
import 'package:hostel_manager/features/announcements/screens/announcement_manage.dart';
import 'package:hostel_manager/features/geofencing/screens/tracking_log_screen.dart';
import 'package:hostel_manager/features/attendance/screens/attendance_screen.dart';
import 'package:hostel_manager/features/attendance/screens/attendance_manage_screen.dart';
import 'package:hostel_manager/features/sos/screens/sos_manage_screen.dart';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';

      return currentUserAsync.when(
        loading: () => null, // stay on current page while loading
        error: (_, _) => isLoggingIn ? null : '/login',
        data: (user) {
          if (user == null) {
            // Not authenticated — send to login.
            return isLoggingIn ? null : '/login';
          }

          // Authenticated — redirect away from login.
          if (isLoggingIn) {
            return user.role == UserRole.warden
                ? '/admin/home'
                : '/student/leave';
          }

          // Prevent students from accessing admin routes and vice-versa.
          final path = state.uri.toString();
          if (user.role == UserRole.student && path.startsWith('/admin')) {
            return '/student/leave';
          }
          if (user.role == UserRole.warden && path.startsWith('/student')) {
            return '/admin/home';
          }

          return null; // no redirect needed
        },
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),

      // Student shell route with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            StudentDashboard(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/leave',
                builder: (_, _) => const LeaveListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/gate',
                builder: (_, _) => const GatePassScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/announcements',
                builder: (_, _) => const AnnouncementFeed(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/student/attendance',
                builder: (_, _) => const AttendanceScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin shell route with sidebar navigation
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AdminDashboard(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/home',
                builder: (_, _) => const AdminHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/leaves',
                builder: (_, _) => const LeaveManageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/passes',
                builder: (_, _) => const GatePassManageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/students',
                builder: (_, _) => const StudentRoster(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/announce',
                builder: (_, _) => const AnnouncementManage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/tracking',
                builder: (_, _) => const TrackingLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/sos',
                builder: (_, _) => const SosManageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/attendance',
                builder: (_, _) => const AttendanceManageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// A [ChangeNotifier] that triggers GoRouter refreshes whenever the
/// [currentUserProvider] value changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(currentUserProvider, (_, _) {
      notifyListeners();
    });
  }
}
