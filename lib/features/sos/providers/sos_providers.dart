import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/sos/models/sos_alert.dart';
import 'package:hostel_manager/features/sos/services/sos_service.dart';

final sosServiceProvider = Provider<SosService>((ref) {
  return SosService();
});

final activeSosAlertsProvider = StreamProvider<List<SosAlert>>((ref) {
  final service = ref.watch(sosServiceProvider);
  return service.getActiveSosAlerts();
});

final allSosAlertsProvider = StreamProvider<List<SosAlert>>((ref) {
  final service = ref.watch(sosServiceProvider);
  return service.getAllSosAlerts();
});
