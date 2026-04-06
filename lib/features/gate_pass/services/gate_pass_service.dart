import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_manager/core/constants/enums.dart';
import 'package:hostel_manager/features/gate_pass/models/gate_pass.dart';
import 'package:uuid/uuid.dart';

class GatePassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _passesRef => _firestore.collection('gatePasses');

  /// Adds a new gate pass request to the `gatePasses` collection.
  Future<void> requestGatePass(GatePass pass) async {
    await _passesRef.doc(pass.id).set(pass.toMap());
  }

  /// Returns a stream of gate passes for a specific student,
  /// ordered by createdAt descending.
  Stream<List<GatePass>> getStudentPasses(String studentId) {
    return _passesRef
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GatePass.fromFirestore(doc)).toList());
  }

  /// Returns a stream of all gate passes, optionally filtered by status.
  Stream<List<GatePass>> getAllPasses({GatePassStatus? status}) {
    Query query = _passesRef.orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GatePass.fromFirestore(doc)).toList());
  }

  /// Approves a gate pass by setting its status to active and generating
  /// a unique QR code token using UUID v4.
  Future<void> approveGatePass(String passId) async {
    final qrToken = _uuid.v4();
    await _passesRef.doc(passId).update({
      'status': GatePassStatus.active.name,
      'qrCodeData': qrToken,
    });
  }

  /// Rejects a gate pass by deleting the document from Firestore.
  Future<void> rejectGatePass(String passId) async {
    await _passesRef.doc(passId).delete();
  }

  /// Looks up a gate pass by its QR code data. Returns the pass if found,
  /// or null otherwise.
  Future<GatePass?> scanGatePass(String qrData) async {
    final snapshot =
        await _passesRef.where('qrCodeData', isEqualTo: qrData).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return GatePass.fromFirestore(snapshot.docs.first);
  }

  /// Records the check-out time and updates status to usedOut.
  Future<void> checkOut(String passId) async {
    await _passesRef.doc(passId).update({
      'actualOut': Timestamp.fromDate(DateTime.now()),
      'status': GatePassStatus.usedOut.name,
    });
  }

  /// Records the check-in time and updates status to usedIn.
  Future<void> checkIn(String passId) async {
    await _passesRef.doc(passId).update({
      'actualIn': Timestamp.fromDate(DateTime.now()),
      'status': GatePassStatus.usedIn.name,
    });
  }

  /// Returns true if the student currently has an active or usedOut pass.
  Future<bool> hasActivePass(String studentId) async {
    final snapshot = await _passesRef
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: [
          GatePassStatus.active.name,
          GatePassStatus.usedOut.name,
        ])
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
