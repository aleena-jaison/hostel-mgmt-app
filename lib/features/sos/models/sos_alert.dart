import 'package:cloud_firestore/cloud_firestore.dart';

class SosAlert {
  final String id;
  final String studentId;
  final String studentName;
  final String? roomNumber;
  final int level; // 1 = emergency
  final String status; // "active", "resolved"
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const SosAlert({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.roomNumber,
    this.level = 1,
    this.status = 'active',
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory SosAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SosAlert(
      id: doc.id,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      roomNumber: data['roomNumber'] as String?,
      level: data['level'] as int? ?? 1,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'roomNumber': roomNumber,
      'level': level,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }
}
