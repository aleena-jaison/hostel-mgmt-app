import 'package:cloud_firestore/cloud_firestore.dart';

class GeofenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _checkinsRef =>
      _firestore.collection('locationCheckins');

  /// Records a location check-in for a student.
  ///
  /// Writes a document to the `locationCheckins` collection with the
  /// student's ID, coordinates, whether they are inside the geofence,
  /// and the current timestamp.
  Future<void> recordCheckin(
    String studentId,
    double lat,
    double lng,
    bool isInside, {
    String? studentName,
  }) async {
    await _checkinsRef.add({
      'studentId': studentId,
      'studentName': studentName ?? '',
      'latitude': lat,
      'longitude': lng,
      'isInsideGeofence': isInside,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Returns a stream of location check-in violations (where
  /// isInsideGeofence == false), ordered by timestamp descending.
  ///
  /// Optionally filters by [date] (matches the same calendar day) and
  /// [studentId].
  Stream<List<Map<String, dynamic>>> getViolations({
    DateTime? date,
    String? studentId,
  }) {
    Query query = _checkinsRef
        .where('isInsideGeofence', isEqualTo: false)
        .orderBy('timestamp', descending: true);

    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Reads the hostel settings document from `config/hostelSettings`.
  ///
  /// Returns the document data as a map, or null if the document does
  /// not exist.
  Future<Map<String, dynamic>?> getHostelSettings() async {
    final doc =
        await _firestore.collection('config').doc('hostelSettings').get();
    if (!doc.exists) return null;
    return doc.data();
  }
}
