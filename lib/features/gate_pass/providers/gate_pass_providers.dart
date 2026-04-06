import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';
import 'package:hostel_manager/features/gate_pass/services/gate_pass_service.dart';

/// Provides a singleton instance of [GatePassService].
final gatePassServiceProvider = Provider<GatePassService>((ref) {
  return GatePassService();
});

/// Streams gate passes for a specific student, ordered by createdAt desc.
final studentPassesProvider =
    StreamProvider.family<List<GatePass>, String>((ref, studentId) {
  final service = ref.watch(gatePassServiceProvider);
  return service.getStudentPasses(studentId);
});

/// Streams all gate passes regardless of status.
final allPassesProvider = StreamProvider<List<GatePass>>((ref) {
  final service = ref.watch(gatePassServiceProvider);
  return service.getAllPasses();
});

/// Streams only active and usedOut gate passes.
final activePassesProvider = StreamProvider<List<GatePass>>((ref) {
  final service = ref.watch(gatePassServiceProvider);
  return service.getAllPasses().map((passes) => passes
      .where((p) =>
          p.status == GatePassStatus.active ||
          p.status == GatePassStatus.usedOut)
      .toList());
});
