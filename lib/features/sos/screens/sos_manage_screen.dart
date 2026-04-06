import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/sos/models/sos_alert.dart';
import 'package:hostel_manager/features/sos/providers/sos_providers.dart';
import 'package:intl/intl.dart';

class SosManageScreen extends ConsumerWidget {
  const SosManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(allSosAlertsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOS Alerts',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: alertsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Center(
                    child: Text('No SOS alerts yet.'),
                  );
                }
                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    return _SosAlertTile(alert: alert);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SosAlertTile extends ConsumerWidget {
  final SosAlert alert;

  const _SosAlertTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = alert.status == 'active';
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      color: isActive
          ? colorScheme.errorContainer
          : colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(
          Icons.emergency,
          color: isActive ? colorScheme.error : colorScheme.outline,
          size: 32,
        ),
        title: Text(
          '${alert.studentName}${alert.roomNumber != null ? ' — Room ${alert.roomNumber}' : ''}',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level ${alert.level} Emergency • ${dateFormat.format(alert.createdAt)}',
            ),
            if (!isActive && alert.resolvedBy != null)
              Text(
                'Resolved by ${alert.resolvedBy}${alert.resolvedAt != null ? ' at ${dateFormat.format(alert.resolvedAt!)}' : ''}',
                style: TextStyle(color: colorScheme.outline),
              ),
          ],
        ),
        trailing: isActive
            ? FilledButton.tonal(
                onPressed: () => _resolveAlert(context, ref),
                child: const Text('Resolve'),
              )
            : Chip(
                label: const Text('Resolved'),
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
      ),
    );
  }

  Future<void> _resolveAlert(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve SOS Alert'),
        content: Text(
          'Mark the SOS alert from ${alert.studentName} as resolved?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final resolvedByName = currentUser?.name ?? 'Warden';
    final sosService = ref.read(sosServiceProvider);
    await sosService.resolveSosAlert(alert.id, resolvedByName);
  }
}
