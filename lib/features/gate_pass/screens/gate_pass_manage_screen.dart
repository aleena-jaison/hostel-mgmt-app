import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';
import 'package:hostel_manager/features/gate_pass/providers/gate_pass_providers.dart';
import 'package:hostel_manager/features/gate_pass/screens/qr_scan_screen.dart';
import 'package:intl/intl.dart';

class GatePassManageScreen extends ConsumerWidget {
  const GatePassManageScreen({super.key});

  static const _tabs = [
    GatePassStatus.pending,
    GatePassStatus.active,
    GatePassStatus.usedOut,
    GatePassStatus.usedIn,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesAsync = ref.watch(allPassesProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Gate Passes'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Active'),
              Tab(text: 'Used Out'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QrScanScreen()),
            );
          },
          child: const Icon(Icons.qr_code_scanner),
        ),
        body: passesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (passes) {
            return TabBarView(
              children: [
                _PassList(
                  passes: passes,
                  emptyMessage: 'No gate passes found.',
                  ref: ref,
                ),
                ..._tabs.map((status) {
                  final filtered =
                      passes.where((p) => p.status == status).toList();
                  return _PassList(
                    passes: filtered,
                    emptyMessage: 'No ${status.label.toLowerCase()} passes.',
                    ref: ref,
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PassList extends StatelessWidget {
  final List<GatePass> passes;
  final String emptyMessage;
  final WidgetRef ref;

  const _PassList({
    required this.passes,
    required this.emptyMessage,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (passes.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: passes.length,
      itemBuilder: (context, index) => _ManagePassCard(
        pass: passes[index],
        ref: ref,
      ),
    );
  }
}

class _ManagePassCard extends StatelessWidget {
  final GatePass pass;
  final WidgetRef ref;

  const _ManagePassCard({required this.pass, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    final service = ref.read(gatePassServiceProvider);

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
                    pass.studentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _StatusChip(status: pass.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Purpose: ${pass.purpose}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text('Expected Out: ${dateFormat.format(pass.expectedOut)}'),
            Text('Expected In: ${dateFormat.format(pass.expectedIn)}'),
            if (pass.actualOut != null)
              Text('Checked Out: ${dateFormat.format(pass.actualOut!)}'),
            if (pass.actualIn != null)
              Text('Checked In: ${dateFormat.format(pass.actualIn!)}'),
            if (pass.status == GatePassStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reject Gate Pass'),
                          content: Text(
                            'Reject gate pass for ${pass.studentName}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await service.rejectGatePass(pass.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gate pass rejected')),
                          );
                        }
                      }
                    },
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      await service.approveGatePass(pass.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gate pass approved')),
                        );
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ],
            if (pass.status == GatePassStatus.active) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Void Gate Pass'),
                          content: Text(
                            'Mark gate pass for ${pass.studentName} as expired?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Void'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        // Void the pass by setting status to expired
                        await ref
                            .read(gatePassServiceProvider)
                            .rejectGatePass(pass.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gate pass voided')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.block),
                    label: const Text('Void'),
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

class _StatusChip extends StatelessWidget {
  final GatePassStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      GatePassStatus.pending => (Colors.orange.shade100, Colors.orange.shade800),
      GatePassStatus.active => (Colors.green.shade100, Colors.green.shade800),
      GatePassStatus.usedOut => (Colors.blue.shade100, Colors.blue.shade800),
      GatePassStatus.usedIn => (Colors.grey.shade200, Colors.grey.shade700),
      GatePassStatus.expired => (Colors.red.shade100, Colors.red.shade800),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
