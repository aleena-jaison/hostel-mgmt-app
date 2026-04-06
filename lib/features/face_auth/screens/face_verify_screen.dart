import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/face_auth/providers/face_auth_providers.dart';

/// Screen for verifying student identity before showing gate pass QR.
/// Returns `true` via Navigator.pop if verification succeeds.
class FaceVerifyScreen extends ConsumerStatefulWidget {
  const FaceVerifyScreen({super.key});

  @override
  ConsumerState<FaceVerifyScreen> createState() => _FaceVerifyScreenState();
}

class _FaceVerifyScreenState extends ConsumerState<FaceVerifyScreen> {
  bool _isProcessing = false;
  int _attempts = 0;
  String? _statusMessage;

  static const _maxAttempts = 3;

  Future<void> _verify() async {
    final faceService = ref.read(faceAuthServiceProvider);
    final user = ref.read(currentUserProvider).value;

    if (user == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Opening camera...';
    });

    final image = await faceService.captureFace();
    if (image == null) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Camera cancelled.';
      });
      return;
    }

    setState(() => _statusMessage = 'Verifying face...');

    final success = await faceService.verifyFace(user.id, image);
    _attempts++;

    if (success) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Verification successful!';
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    final remaining = _maxAttempts - _attempts;
    setState(() {
      _isProcessing = false;
      _statusMessage = remaining > 0
          ? 'Verification failed. $remaining attempt${remaining == 1 ? '' : 's'} remaining.'
          : 'Verification failed. Please contact the warden.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _attempts >= _maxAttempts;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLocked ? Icons.lock : Icons.verified_user,
                size: 100,
                color: isLocked
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                isLocked ? 'Locked' : 'Verify Your Identity',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                isLocked
                    ? 'Too many failed attempts. Please contact the warden.'
                    : 'Look at the camera for face verification.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('success')
                        ? Colors.green
                        : _statusMessage!.contains('failed')
                            ? Colors.red
                            : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (_isProcessing)
                const CircularProgressIndicator()
              else if (!isLocked)
                FilledButton.icon(
                  onPressed: _verify,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Face'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
