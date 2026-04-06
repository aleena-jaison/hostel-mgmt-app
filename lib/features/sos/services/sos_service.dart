import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_manager/features/sos/models/sos_alert.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection => _firestore.collection('sosAlerts');

  Future<void> sendSosAlert(SosAlert alert) async {
    await _collection.add(alert.toMap());
  }

  Stream<List<SosAlert>> getActiveSosAlerts() {
    return _collection
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SosAlert.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<SosAlert>> getAllSosAlerts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SosAlert.fromFirestore(doc)).toList(),
        );
  }

  Future<void> resolveSosAlert(String alertId, String resolvedByName) async {
    await _collection.doc(alertId).update({
      'status': 'resolved',
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'resolvedBy': resolvedByName,
    });
  }
}
