import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class GatePassLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _locationsRef =>
      _firestore.collection('gatePassLocations');

  /// Updates the student's live location in Firestore.
  /// Uses a document keyed by the gatePassId so each active gate pass
  /// has exactly one location doc that gets overwritten.
  Future<void> updateLocation({
    required String gatePassId,
    required String studentId,
    required String studentName,
    required double latitude,
    required double longitude,
  }) async {
    await _locationsRef.doc(gatePassId).set({
      'gatePassId': gatePassId,
      'studentId': studentId,
      'studentName': studentName,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Removes the location document when the student checks back in.
  Future<void> removeLocation(String gatePassId) async {
    await _locationsRef.doc(gatePassId).delete();
  }

  /// Streams all active gate pass locations for the warden map view.
  Stream<List<StudentGatePassLocation>> getActiveGatePassLocations() {
    return _locationsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => StudentGatePassLocation.fromFirestore(doc))
        .toList());
  }

  /// Gets the current GPS position with permission handling.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. '
        'Please enable them in app settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}

class StudentGatePassLocation {
  final String gatePassId;
  final String studentId;
  final String studentName;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const StudentGatePassLocation({
    required this.gatePassId,
    required this.studentId,
    required this.studentName,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  factory StudentGatePassLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentGatePassLocation(
      gatePassId: doc.id,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
