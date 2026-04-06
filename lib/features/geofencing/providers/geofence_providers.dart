import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/geofencing/services/geofence_service.dart';
import 'package:hostel_manager/features/geofencing/services/location_service.dart';

/// Provides a singleton instance of [LocationService].
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provides a singleton instance of [GeofenceService].
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return GeofenceService();
});

/// Streams all geofence violations (check-ins where isInsideGeofence == false),
/// ordered by timestamp descending.
final violationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(geofenceServiceProvider);
  return service.getViolations();
});

/// Fetches hostel settings from Firestore config/hostelSettings document.
final hostelSettingsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.watch(geofenceServiceProvider);
  return service.getHostelSettings();
});
