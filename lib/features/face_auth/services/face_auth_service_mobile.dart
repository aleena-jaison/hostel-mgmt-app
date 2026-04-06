import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_auth_service_base.dart';

/// Mobile implementation using Google ML Kit for face detection and
/// MobileFaceNet (TFLite) for 192-dim face embeddings.
class FaceAuthServicePlatform extends FaceAuthService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  Interpreter? _interpreter;
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.15,
    ),
  );

  // MobileFaceNet expects 112x112 input and outputs 192-dim embedding.
  static const _inputSize = 112;
  static const _embeddingSize = 192;
  static const _similarityThreshold = 0.7;

  /// Load the TFLite model if not already loaded.
  Future<void> _ensureModel() async {
    if (_interpreter != null) return;
    _interpreter = await Interpreter.fromAsset('models/mobilefacenet.tflite');
  }

  /// Capture a face image using the front camera.
  @override
  Future<XFile?> captureFace() async {
    return _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 90,
    );
  }

  /// Detect the largest face in the image and return the cropped face region.
  Future<img.Image?> _detectAndCropFace(Uint8List imageBytes, String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) return null;

    // Pick the largest face.
    final face = faces.reduce(
      (a, b) =>
          a.boundingBox.width * a.boundingBox.height >
                  b.boundingBox.width * b.boundingBox.height
              ? a
              : b,
    );

    // Decode the full image.
    final fullImage = img.decodeImage(imageBytes);
    if (fullImage == null) return null;

    // Expand bounding box by 20% for better cropping.
    final bb = face.boundingBox;
    final padX = bb.width * 0.2;
    final padY = bb.height * 0.2;

    final x = (bb.left - padX).clamp(0, fullImage.width - 1).toInt();
    final y = (bb.top - padY).clamp(0, fullImage.height - 1).toInt();
    final w = (bb.width + padX * 2)
        .clamp(1, fullImage.width - x)
        .toInt();
    final h = (bb.height + padY * 2)
        .clamp(1, fullImage.height - y)
        .toInt();

    // Crop and resize to model input size.
    final cropped = img.copyCrop(fullImage, x: x, y: y, width: w, height: h);
    return img.copyResize(cropped,
        width: _inputSize, height: _inputSize);
  }

  /// Run the cropped face through MobileFaceNet to get a 192-dim embedding.
  Future<List<double>> _getEmbedding(img.Image face) async {
    await _ensureModel();

    // Prepare input: [1, 112, 112, 3] float32 tensor, normalized to [-1, 1].
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = face.getPixel(x, y);
            return [
              (pixel.r.toDouble() - 127.5) / 127.5,
              (pixel.g.toDouble() - 127.5) / 127.5,
              (pixel.b.toDouble() - 127.5) / 127.5,
            ];
          },
        ),
      ),
    );

    // Output: [1, 192] float32 tensor.
    final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0));

    _interpreter!.run(input, output);

    // L2-normalize the embedding.
    final embedding = output[0];
    final norm = sqrt(embedding.fold(0.0, (acc, v) => acc + v * v));
    if (norm > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] /= norm;
      }
    }

    return embedding;
  }

  /// Encode an embedding vector to base64 for storage.
  String _encodeEmbedding(List<double> embedding) {
    final bytes = Float64List.fromList(embedding);
    return base64Encode(bytes.buffer.asUint8List());
  }

  /// Decode a base64 string back to an embedding vector.
  List<double> _decodeEmbedding(String base64Str) {
    final bytes = base64Decode(base64Str);
    return Float64List.view(bytes.buffer).toList();
  }

  /// Cosine similarity between two L2-normalized embedding vectors.
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dot = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    // For L2-normalized vectors, cosine similarity = dot product.
    return dot;
  }

  /// Enroll a student's face: detect face, extract embedding, upload photo.
  @override
  Future<bool> enrollFace(String userId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Detect and crop face.
      final croppedFace = await _detectAndCropFace(bytes, imageFile.path);
      if (croppedFace == null) return false;

      // Get embedding from the cropped face.
      final embedding = await _getEmbedding(croppedFace);

      // Upload the original photo as reference.
      final ref = _storage.ref().child('faces/$userId.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final photoUrl = await ref.getDownloadURL();

      // Store embedding and photo URL.
      await _firestore.collection('users').doc(userId).update({
        'faceEmbedding': _encodeEmbedding(embedding),
        'profileImageUrl': photoUrl,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verify a live face against the stored embedding for a user.
  @override
  Future<bool> verifyFace(String userId, XFile imageFile) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final storedStr = doc.data()?['faceEmbedding'] as String?;
      if (storedStr == null) return false;

      final storedEmbedding = _decodeEmbedding(storedStr);

      final bytes = await imageFile.readAsBytes();
      final croppedFace = await _detectAndCropFace(bytes, imageFile.path);
      if (croppedFace == null) return false;

      final liveEmbedding = await _getEmbedding(croppedFace);

      final similarity = _cosineSimilarity(liveEmbedding, storedEmbedding);
      return similarity >= _similarityThreshold;
    } catch (e) {
      return false;
    }
  }

  /// Check if a user has enrolled their face.
  @override
  Future<bool> hasEnrolledFace(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final embedding = doc.data()?['faceEmbedding'] as String?;
    return embedding != null && embedding.isNotEmpty;
  }

  /// Clean up resources.
  @override
  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}

FaceAuthService createFaceAuthService() => FaceAuthServicePlatform();
