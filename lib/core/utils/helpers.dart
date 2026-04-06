import 'dart:math';

import 'package:intl/intl.dart';

/// Returns the haversine distance between two coordinates in meters.
double haversineDistance(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadius = 6371000.0; // meters

  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLng / 2) *
          sin(dLng / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * pi / 180;

/// Formats a [DateTime] as "dd MMM yyyy" (e.g. "02 Apr 2026").
String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy').format(date);
}

/// Formats a [DateTime] as "dd MMM yyyy, hh:mm a" (e.g. "02 Apr 2026, 03:30 PM").
String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(date);
}
