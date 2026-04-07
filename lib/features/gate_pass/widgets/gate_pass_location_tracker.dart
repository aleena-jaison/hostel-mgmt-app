import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';
import 'package:hostel_manager/features/gate_pass/providers/gate_pass_providers.dart';

/// A widget that sits in the widget tree and periodically sends the
/// student's location to Firestore while they have a gate pass with
/// status `usedOut` (checked out but not yet checked back in).
class GatePassLocationTracker extends ConsumerStatefulWidget {
  final Widget child;

  const GatePassLocationTracker({super.key, required this.child});

  @override
  ConsumerState<GatePassLocationTracker> createState() =>
      _GatePassLocationTrackerState();
}

class _GatePassLocationTrackerState
    extends ConsumerState<GatePassLocationTracker> {
  Timer? _timer;
  String? _activePassId;

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  void _startTracking(String passId) {
    if (_activePassId == passId) return; // already tracking this pass
    _stopTracking();
    _activePassId = passId;

    // Send immediately, then every 30 seconds
    _sendLocation(passId);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendLocation(passId);
    });
  }

  void _stopTracking() {
    _timer?.cancel();
    _timer = null;
    if (_activePassId != null) {
      final service = ref.read(gatePassLocationServiceProvider);
      service.removeLocation(_activePassId!);
      _activePassId = null;
    }
  }

  Future<void> _sendLocation(String passId) async {
    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) return;

      final service = ref.read(gatePassLocationServiceProvider);
      final position = await service.getCurrentPosition();

      await service.updateLocation(
        gatePassId: passId,
        studentId: currentUser.id,
        studentName: currentUser.name,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Silently ignore location errors — tracking is best-effort
    }
  }

  GatePass? _findUsedOutPass(List<GatePass> passes) {
    for (final pass in passes) {
      if (pass.status == GatePassStatus.usedOut) {
        return pass;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser != null) {
      final passesAsync = ref.watch(studentPassesProvider(currentUser.id));

      passesAsync.whenData((passes) {
        final usedOutPass = _findUsedOutPass(passes);
        if (usedOutPass != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startTracking(usedOutPass.id);
          });
        } else if (_activePassId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _stopTracking();
          });
        }
      });
    }

    return widget.child;
  }
}
