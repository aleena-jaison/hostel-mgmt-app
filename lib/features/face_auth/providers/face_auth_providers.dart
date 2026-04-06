import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/face_auth/services/face_auth_service.dart';

final faceAuthServiceProvider = Provider<FaceAuthService>((ref) {
  return createFaceAuthService();
});
