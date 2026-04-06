import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';

class QrDisplayScreen extends ConsumerWidget {
  final GatePass pass;
  const QrDisplayScreen({super.key, required this.pass});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM dd, yyyy  hh:mm a');

    // TODO: Set screen brightness to max using a plugin like screen_brightness
    // to make it easier for the scanner to read the QR code.

    return Scaffold(
      appBar: AppBar(title: const Text('Gate Pass QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              pass.studentName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gate Pass',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: pass.qrCodeData,
                version: QrVersions.auto,
                size: 280,
                gapless: true,
              ),
            ),
            const SizedBox(height: 32),
            _DetailRow(label: 'Purpose', value: pass.purpose),
            const Divider(),
            _DetailRow(
              label: 'Expected Out',
              value: dateFormat.format(pass.expectedOut),
            ),
            const Divider(),
            _DetailRow(
              label: 'Expected In',
              value: dateFormat.format(pass.expectedIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
