import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, onLeave }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.onLeave => 'On Leave',
      };

  static AttendanceStatus fromString(String value) => switch (value) {
        'present' => AttendanceStatus.present,
        'absent' => AttendanceStatus.absent,
        'on_leave' => AttendanceStatus.onLeave,
        _ => AttendanceStatus.absent,
      };

  String toFirestore() => switch (this) {
        AttendanceStatus.present => 'present',
        AttendanceStatus.absent => 'absent',
        AttendanceStatus.onLeave => 'on_leave',
      };
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String date; // "yyyy-MM-dd" format
  final AttendanceStatus status;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? markedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.status,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.markedAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      date: data['date'] ?? '',
      status: AttendanceStatusX.fromString(data['status'] ?? 'absent'),
      photoUrl: data['photoUrl'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      markedAt: (data['markedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'date': date,
      'status': status.toFirestore(),
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : null,
    };
  }
}
