import 'package:image_picker/image_picker.dart';

/// Platform-agnostic interface for face authentication.
/// Mobile uses ML Kit + TFLite; web uses a stub since native ML isn't available.
abstract class FaceAuthService {
  Future<XFile?> captureFace();
  Future<bool> enrollFace(String userId, XFile imageFile);
  Future<bool> verifyFace(String userId, XFile imageFile);
  Future<bool> hasEnrolledFace(String userId);
  void dispose();
}
