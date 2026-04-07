import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/leave/models/leave_request.dart';
import 'package:hostel_manager/features/leave/providers/leave_providers.dart';
import 'package:go_router/go_router.dart';

class LeaveListScreen extends ConsumerWidget {
  const LeaveListScreen({super.key});

  Color _statusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final dateFormat = DateFormat('dd MMM yyyy');

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final leavesAsync = ref.watch(studentLeavesProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(title: const Text('My Leaves')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'leave_list_add',
        onPressed: () => context.push('/apply-leave'),
        child: const Icon(Icons.add),
      ),
      body: leavesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (leaves) {
          if (leaves.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy,
                      size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  const Text(
                    'No leave requests yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return _LeaveCard(
                leave: leave,
                dateFormat: dateFormat,
                statusColor: _statusColor(leave.status),
              );
            },
          );
        },
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final DateFormat dateFormat;
  final Color statusColor;

  const _LeaveCard({
    required this.leave,
    required this.dateFormat,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(leave.type.label),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    leave.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(leave.reason, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${dateFormat.format(leave.fromDate)} — ${dateFormat.format(leave.toDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (leave.wardenRemarks != null &&
                leave.wardenRemarks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Warden: ${leave.wardenRemarks}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
