import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/leave/models/leave_request.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _leaveRequests =>
      _firestore.collection('leaveRequests');

  Future<void> createLeaveRequest(LeaveRequest request) async {
    await _leaveRequests.add(request.toMap());
  }

  Stream<List<LeaveRequest>> getStudentLeaves(String studentId) {
    return _leaveRequests
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveRequest.fromFirestore(doc))
            .toList());
  }

  Stream<List<LeaveRequest>> getAllLeaves({LeaveStatus? status}) {
    Query query = _leaveRequests.orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList());
  }

  Future<void> updateLeaveStatus(
    String requestId,
    LeaveStatus status, {
    String? remarks,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (remarks != null) {
      data['wardenRemarks'] = remarks;
    }
    await _leaveRequests.doc(requestId).update(data);
  }
}
