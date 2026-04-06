import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/leave/models/leave_request.dart';
import 'package:hostel_manager/features/leave/providers/leave_providers.dart';

class LeaveManageScreen extends ConsumerWidget {
  const LeaveManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Leaves'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaveTab(statusFilter: null, ref: ref),
            _LeaveTab(statusFilter: LeaveStatus.pending, ref: ref),
            _LeaveTab(statusFilter: LeaveStatus.approved, ref: ref),
            _LeaveTab(statusFilter: LeaveStatus.rejected, ref: ref),
          ],
        ),
      ),
    );
  }
}

class _LeaveTab extends StatelessWidget {
  final LeaveStatus? statusFilter;
  final WidgetRef ref;

  const _LeaveTab({required this.statusFilter, required this.ref});

  @override
  Widget build(BuildContext context) {
    final leavesAsync = ref.watch(allLeavesProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return leavesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (allLeaves) {
        final leaves = statusFilter == null
            ? allLeaves
            : allLeaves
                .where((leave) => leave.status == statusFilter)
                .toList();

        if (leaves.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox,
                    size: 64, color: Theme.of(context).disabledColor),
                const SizedBox(height: 16),
                const Text(
                  'No leave requests',
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
            return _ManageLeaveCard(
              leave: leave,
              dateFormat: dateFormat,
              ref: ref,
            );
          },
        );
      },
    );
  }
}

class _ManageLeaveCard extends StatelessWidget {
  final LeaveRequest leave;
  final DateFormat dateFormat;
  final WidgetRef ref;

  const _ManageLeaveCard({
    required this.leave,
    required this.dateFormat,
    required this.ref,
  });

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

  Future<void> _handleAction(
    BuildContext context,
    LeaveStatus newStatus,
  ) async {
    final remarksController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newStatus == LeaveStatus.approved ? 'Approve Leave' : 'Reject Leave',
        ),
        content: TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            labelText: 'Remarks (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              newStatus == LeaveStatus.approved ? 'Approve' : 'Reject',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final leaveService = ref.read(leaveServiceProvider);
        final remarks = remarksController.text.trim();
        await leaveService.updateLeaveStatus(
          leave.id,
          newStatus,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Leave ${newStatus == LeaveStatus.approved ? 'approved' : 'rejected'}',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    }

    remarksController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(leave.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    leave.studentName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
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
            Chip(
              label: Text(leave.type.label),
              visualDensity: VisualDensity.compact,
            ),
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
            const SizedBox(height: 8),
            Text(leave.reason, style: Theme.of(context).textTheme.bodyMedium),
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
                      'Remarks: ${leave.wardenRemarks}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
            if (leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _handleAction(context, LeaveStatus.rejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () =>
                        _handleAction(context, LeaveStatus.approved),
                    child: const Text('Approve'),
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
