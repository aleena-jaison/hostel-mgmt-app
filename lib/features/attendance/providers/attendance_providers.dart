import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/attendance/models/attendance_record.dart';
import 'package:hostel_manager/features/attendance/services/attendance_service.dart';
import 'package:intl/intl.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final todayAttendanceProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, date) {
  final service = ref.read(attendanceServiceProvider);
  return service.getAttendanceByDate(date);
});

final todayDateProvider = Provider<String>((ref) {
  return DateFormat('yyyy-MM-dd').format(DateTime.now());
});

/// Real-time stream of hostel settings. Updates instantly when the warden
/// changes attendance time or window from the admin panel.
final hostelSettingsStreamProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  return FirebaseFirestore.instance
      .collection('config')
      .doc('hostelSettings')
      .snapshots()
      .map((snap) => snap.data());
});
