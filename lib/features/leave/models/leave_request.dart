import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hostel_manager/core/constants/enums.dart';

class LeaveRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String reason;
  final LeaveType type;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveStatus status;
  final String? wardenRemarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LeaveRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.reason,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.status,
    this.wardenRemarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaveRequest(
      id: doc.id,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      reason: data['reason'] as String,
      type: LeaveType.fromString(data['type'] as String),
      fromDate: (data['fromDate'] as Timestamp).toDate(),
      toDate: (data['toDate'] as Timestamp).toDate(),
      status: LeaveStatus.fromString(data['status'] as String),
      wardenRemarks: data['wardenRemarks'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'reason': reason,
      'type': type.name,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'status': status.name,
      'wardenRemarks': wardenRemarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
