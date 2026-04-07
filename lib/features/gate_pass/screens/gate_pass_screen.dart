import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';
import 'package:hostel_manager/features/gate_pass/providers/gate_pass_providers.dart';
import 'package:hostel_manager/features/gate_pass/screens/qr_display_screen.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class GatePassScreen extends ConsumerWidget {
  const GatePassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final passesAsync = ref.watch(studentPassesProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(title: const Text('My Gate Passes')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'gate_pass_add',
        onPressed: () => _showRequestSheet(context, ref, currentUser.id, currentUser.name),
        child: const Icon(Icons.add),
      ),
      body: passesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (passes) {
          if (passes.isEmpty) {
            return const Center(
              child: Text('No gate passes yet.\nTap + to request one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: passes.length,
            itemBuilder: (context, index) => _PassCard(pass: passes[index]),
          );
        },
      ),
    );
  }

  void _showRequestSheet(
    BuildContext context,
    WidgetRef ref,
    String studentId,
    String studentName,
  ) {
    final purposeController = TextEditingController();
    DateTime? expectedOut;
    DateTime? expectedIn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final dateFormat = DateFormat('MMM dd, yyyy  hh:mm a');
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Request Gate Pass',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(expectedOut != null
                        ? 'Out: ${dateFormat.format(expectedOut!)}'
                        : 'Select expected out time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final dt = await _pickDateTime(ctx);
                      if (dt != null) setState(() => expectedOut = dt);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(expectedIn != null
                        ? 'In: ${dateFormat.format(expectedIn!)}'
                        : 'Select expected in time'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final dt = await _pickDateTime(ctx);
                      if (dt != null) setState(() => expectedIn = dt);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      if (purposeController.text.trim().isEmpty ||
                          expectedOut == null ||
                          expectedIn == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Please fill all fields')),
                        );
                        return;
                      }
                      if (expectedIn!.isBefore(expectedOut!)) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Expected in time must be after expected out time')),
                        );
                        return;
                      }
                      final pass = GatePass(
                        id: const Uuid().v4(),
                        studentId: studentId,
                        studentName: studentName,
                        qrCodeData: '',
                        purpose: purposeController.text.trim(),
                        expectedOut: expectedOut!,
                        expectedIn: expectedIn!,
                        status: GatePassStatus.pending,
                        createdAt: DateTime.now(),
                      );
                      ref
                          .read(gatePassServiceProvider)
                          .requestGatePass(pass);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Submit Request'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return null;

    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

class _PassCard extends StatelessWidget {
  final GatePass pass;
  const _PassCard({required this.pass});

  bool get _isExpiredActive =>
      pass.status == GatePassStatus.active &&
      DateTime.now().difference(pass.expectedOut).inHours >= 3;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
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
                    pass.purpose,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _isExpiredActive
                    ? const _StatusBadge(status: GatePassStatus.expired)
                    : _StatusBadge(status: pass.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Out: ${dateFormat.format(pass.expectedOut)}'),
            Text('In: ${dateFormat.format(pass.expectedIn)}'),
            if (pass.status == GatePassStatus.active &&
                DateTime.now().difference(pass.expectedOut).inHours >= 3) ...[
              const SizedBox(height: 12),
              Text(
                'Expired — not checked out before expected time',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else if (pass.status == GatePassStatus.active) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QrDisplayScreen(pass: pass),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Check Out QR'),
                ),
              ),
            ] else if (pass.status == GatePassStatus.usedOut) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QrDisplayScreen(pass: pass),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Check In QR'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final GatePassStatus status;
  const _StatusBadge({required this.status});

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
