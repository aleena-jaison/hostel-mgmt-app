import 'package:image_picker/image_picker.dart';

import 'face_auth_service_base.dart';

/// Stub implementation for web — face auth is only used on mobile.
class FaceAuthServicePlatform extends FaceAuthService {
  @override
  Future<XFile?> captureFace() async => null;

  @override
  Future<bool> enrollFace(String userId, XFile imageFile) async => false;

  @override
  Future<bool> verifyFace(String userId, XFile imageFile) async => false;

  @override
  Future<bool> hasEnrolledFace(String userId) async => false;

  @override
  void dispose() {}
}

FaceAuthService createFaceAuthService() => FaceAuthServicePlatform();
