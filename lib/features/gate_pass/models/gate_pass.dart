import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_manager/core/constants/enums.dart';

class GatePass {
  final String id;
  final String studentId;
  final String studentName;
  final String? leaveRequestId;
  final String qrCodeData;
  final String purpose;
  final DateTime expectedOut;
  final DateTime expectedIn;
  final DateTime? actualOut;
  final DateTime? actualIn;
  final GatePassStatus status;
  final DateTime createdAt;

  const GatePass({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.leaveRequestId,
    required this.qrCodeData,
    required this.purpose,
    required this.expectedOut,
    required this.expectedIn,
    this.actualOut,
    this.actualIn,
    required this.status,
    required this.createdAt,
  });

  factory GatePass.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GatePass(
      id: doc.id,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      leaveRequestId: data['leaveRequestId'] as String?,
      qrCodeData: data['qrCodeData'] as String? ?? '',
      purpose: data['purpose'] as String,
      expectedOut: (data['expectedOut'] as Timestamp).toDate(),
      expectedIn: (data['expectedIn'] as Timestamp).toDate(),
      actualOut: data['actualOut'] != null
          ? (data['actualOut'] as Timestamp).toDate()
          : null,
      actualIn: data['actualIn'] != null
          ? (data['actualIn'] as Timestamp).toDate()
          : null,
      status: GatePassStatus.fromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'leaveRequestId': leaveRequestId,
      'qrCodeData': qrCodeData,
      'purpose': purpose,
      'expectedOut': Timestamp.fromDate(expectedOut),
      'expectedIn': Timestamp.fromDate(expectedIn),
      'actualOut': actualOut != null ? Timestamp.fromDate(actualOut!) : null,
      'actualIn': actualIn != null ? Timestamp.fromDate(actualIn!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
