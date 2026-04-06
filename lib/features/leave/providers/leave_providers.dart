import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/leave/models/leave_request.dart';
import 'package:hostel_manager/features/leave/services/leave_service.dart';

final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService();
});

final studentLeavesProvider =
    StreamProvider.family<List<LeaveRequest>, String>((ref, studentId) {
  final leaveService = ref.watch(leaveServiceProvider);
  return leaveService.getStudentLeaves(studentId);
});

final allLeavesProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final leaveService = ref.watch(leaveServiceProvider);
  return leaveService.getAllLeaves();
});

final pendingLeavesProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final leaveService = ref.watch(leaveServiceProvider);
  return leaveService.getAllLeaves(status: LeaveStatus.pending);
});
