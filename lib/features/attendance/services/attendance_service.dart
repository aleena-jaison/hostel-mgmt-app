import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hostel_manager/features/attendance/models/attendance_record.dart';

class AttendanceService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Check if a student is currently on approved leave for the given date.
  Future<bool> isOnApprovedLeave(String studentId, DateTime date) async {
    final snapshot = await _firestore
        .collection('leaveRequests')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'approved')
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final fromDate = (data['fromDate'] as Timestamp).toDate();
      final toDate = (data['toDate'] as Timestamp).toDate();

      // Check if today falls within the leave period
      final dateOnly = DateTime(date.year, date.month, date.day);
      final fromOnly = DateTime(fromDate.year, fromDate.month, fromDate.day);
      final toOnly = DateTime(toDate.year, toDate.month, toDate.day);

      if (!dateOnly.isBefore(fromOnly) && !dateOnly.isAfter(toOnly)) {
        return true;
      }
    }
    return false;
  }

  /// Check if attendance has already been marked for today.
  Future<AttendanceRecord?> getTodayAttendance(
      String studentId, String date) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AttendanceRecord.fromFirestore(snapshot.docs.first);
  }

  /// Upload attendance selfie and return the download URL.
  Future<String> uploadAttendancePhoto(
      String studentId, String date, Uint8List photoBytes) async {
    final ref =
        _storage.ref().child('attendance/$date/$studentId.jpg');
    await ref.putData(
        photoBytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Mark attendance as present with photo and location.
  Future<void> markPresent({
    required String studentId,
    required String studentName,
    required String date,
    required String photoUrl,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore.collection('attendance').add({
      'studentId': studentId,
      'studentName': studentName,
      'date': date,
      'status': 'present',
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'markedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Auto-mark attendance as on leave.
  Future<void> markOnLeave({
    required String studentId,
    required String studentName,
    required String date,
  }) async {
    await _firestore.collection('attendance').add({
      'studentId': studentId,
      'studentName': studentName,
      'date': date,
      'status': 'on_leave',
      'photoUrl': null,
      'latitude': null,
      'longitude': null,
      'markedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get all attendance records for a specific date (warden view).
  Stream<List<AttendanceRecord>> getAttendanceByDate(String date) {
    return _firestore
        .collection('attendance')
        .where('date', isEqualTo: date)
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList());
  }

  /// Get a student's attendance history.
  Stream<List<AttendanceRecord>> getStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList());
  }

  /// Get attendance settings from hostel config.
  Future<Map<String, dynamic>?> getAttendanceSettings() async {
    final doc =
        await _firestore.collection('config').doc('hostelSettings').get();
    return doc.data();
  }
}
