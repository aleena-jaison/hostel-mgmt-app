import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hostel_manager/shared/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Signs in with email and password, then fetches the user document
  /// from Firestore and returns a [UserModel]. Returns null if the
  /// user document does not exist.
  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc);
  }

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// A stream that emits whenever the authentication state changes
  /// (sign-in, sign-out, token refresh).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;
}
