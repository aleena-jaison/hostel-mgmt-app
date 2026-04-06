import 'package:geolocator/geolocator.dart';
import 'package:hostel_manager/core/utils/helpers.dart';

class LocationService {
  /// Returns the current GPS position with high accuracy.
  ///
  /// Checks and requests location permissions before fetching the position.
  /// Throws an exception if location services are disabled or permissions
  /// are denied.
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

  /// Returns true if the given [lat], [lng] is within [radiusMeters] of
  /// the center point [centerLat], [centerLng].
  ///
  /// Uses the haversine formula from helpers.dart.
  Future<bool> isInsideGeofence(
    double lat,
    double lng,
    double centerLat,
    double centerLng,
    double radiusMeters,
  ) async {
    final distance = haversineDistance(lat, lng, centerLat, centerLng);
    return distance <= radiusMeters;
  }
}
