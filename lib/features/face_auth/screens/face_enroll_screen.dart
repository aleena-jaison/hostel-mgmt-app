import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/face_auth/providers/face_auth_providers.dart';

class FaceEnrollScreen extends ConsumerStatefulWidget {
  const FaceEnrollScreen({super.key});

  @override
  ConsumerState<FaceEnrollScreen> createState() => _FaceEnrollScreenState();
}

class _FaceEnrollScreenState extends ConsumerState<FaceEnrollScreen> {
  bool _isProcessing = false;
  String? _statusMessage;

  Future<void> _enrollFace() async {
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

    setState(() => _statusMessage = 'Detecting face & extracting features...');

    final success = await faceService.enrollFace(user.id, image);

    setState(() {
      _isProcessing = false;
      _statusMessage = success
          ? 'Face enrolled successfully!'
          : 'No face detected or enrollment failed. Ensure good lighting and face the camera directly.';
    });

    if (success && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Enrollment')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.face,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Enroll Your Face',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Take a clear photo of your face for identity verification. '
                'Make sure you are in a well-lit area.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_statusMessage != null) ...[
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusMessage!.contains('success')
                        ? Colors.green
                        : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (_isProcessing)
                const CircularProgressIndicator()
              else
                FilledButton.icon(
                  onPressed: _enrollFace,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Face'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
