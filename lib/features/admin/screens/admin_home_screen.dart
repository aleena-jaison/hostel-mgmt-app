import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  children: const [
                    _SummaryCard(
                      icon: Icons.pending_actions,
                      label: 'Pending Leaves',
                      stream: _pendingLeavesStream,
                      color: Colors.orange,
                    ),
                    _SummaryCard(
                      icon: Icons.exit_to_app,
                      label: 'Students Out',
                      stream: _studentsOutStream,
                      color: Colors.red,
                    ),
                    _SummaryCard(
                      icon: Icons.warning_amber,
                      label: 'Violations Today',
                      stream: _violationsTodayStream,
                      color: Colors.deepOrange,
                    ),
                    _SummaryCard(
                      icon: Icons.school,
                      label: 'Total Students',
                      stream: _totalStudentsStream,
                      color: Colors.blue,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

typedef _CountStreamBuilder = Stream<QuerySnapshot> Function();

Stream<QuerySnapshot> _pendingLeavesStream() {
  return FirebaseFirestore.instance
      .collection('leaveRequests')
      .where('status', isEqualTo: 'pending')
      .snapshots();
}

Stream<QuerySnapshot> _studentsOutStream() {
  return FirebaseFirestore.instance
      .collection('gatePasses')
      .where('status', isEqualTo: 'used_out')
      .snapshots();
}

Stream<QuerySnapshot> _violationsTodayStream() {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('locationCheckins')
      .where('isInsideGeofence', isEqualTo: false)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots();
}

Stream<QuerySnapshot> _totalStudentsStream() {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'student')
      .snapshots();
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final _CountStreamBuilder stream;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.stream,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: stream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    '--',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                  );
                }

                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final count = snapshot.data!.docs.length;
                return Text(
                  '$count',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
