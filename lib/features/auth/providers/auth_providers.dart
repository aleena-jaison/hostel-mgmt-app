import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/auth/services/auth_service.dart';
import 'package:hostel_manager/shared/models/user_model.dart';

/// Provides a singleton instance of [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Watches the Firebase Auth state and emits the current [User?] whenever
/// sign-in or sign-out occurs.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Fetches the [UserModel] from Firestore for the currently authenticated
/// Firebase user. Returns null if no user is signed in or if the user
/// document does not exist.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    },
    loading: () => null,
    error: (_, _) => null,
  );
});
