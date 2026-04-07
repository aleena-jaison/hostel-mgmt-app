import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';
import 'package:hostel_manager/features/gate_pass/providers/gate_pass_providers.dart';
import 'package:intl/intl.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Gate Pass')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Point the camera at a gate pass QR code',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);
    _scannerController.stop();

    final scannedData = barcode.rawValue!;
    final service = ref.read(gatePassServiceProvider);

    try {
      final pass = await service.scanGatePass(scannedData);

      if (!mounted) return;

      if (pass == null) {
        _showResultDialog(
          title: 'Not Found',
          message: 'No gate pass found for this QR code.',
          isError: true,
        );
        return;
      }

      if (pass.status == GatePassStatus.active &&
          DateTime.now().difference(pass.expectedOut).inHours >= 3) {
        _showResultDialog(
          title: 'Expired Pass',
          message:
              '${pass.studentName}\'s pass has expired — they did not check out before the expected time.',
          isError: true,
        );
      } else if (pass.status == GatePassStatus.active) {
        _showPassActionDialog(pass: pass, isCheckOut: true);
      } else if (pass.status == GatePassStatus.usedOut) {
        _showPassActionDialog(pass: pass, isCheckOut: false);
      } else {
        _showResultDialog(
          title: 'Invalid Pass',
          message:
              'This pass has status "${pass.status.label}" and cannot be used.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showResultDialog(
        title: 'Error',
        message: 'Failed to look up gate pass: $e',
        isError: true,
      );
    }
  }

  void _showPassActionDialog({required GatePass pass, required bool isCheckOut}) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isCheckOut ? 'Check Out' : 'Check In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Student: ${pass.studentName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Purpose: ${pass.purpose}'),
              Text('Expected Out: ${dateFormat.format(pass.expectedOut)}'),
              Text('Expected In: ${dateFormat.format(pass.expectedIn)}'),
              if (pass.actualOut != null)
                Text('Checked Out: ${dateFormat.format(pass.actualOut!)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resumeScanner();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final service = ref.read(gatePassServiceProvider);
                try {
                  if (isCheckOut) {
                    await service.checkOut(pass.id);
                  } else {
                    await service.checkIn(pass.id);
                  }
                  if (!mounted) return;
                  _showResultDialog(
                    title: 'Success',
                    message: isCheckOut
                        ? '${pass.studentName} checked out successfully.'
                        : '${pass.studentName} checked in successfully.',
                    isError: false,
                  );
                } catch (e) {
                  if (!mounted) return;
                  _showResultDialog(
                    title: 'Error',
                    message: 'Operation failed: $e',
                    isError: true,
                  );
                }
              },
              child: Text(isCheckOut ? 'Check Out' : 'Check In'),
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isError,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.red : Colors.green,
            size: 48,
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _resumeScanner();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resumeScanner() {
    setState(() => _isProcessing = false);
    _scannerController.start();
  }
}
