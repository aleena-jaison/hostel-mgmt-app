// Run this script ONCE to create the warden account.
// Usage: dart run scripts/seed_warden.dart
//
// After running, the warden can log in with:
//   Email: warden@hostel.com
//   Password: Warden@123
//
// NOTE: This script uses the Firebase REST API directly since
// firebase_auth requires Flutter. You can also create the warden
// manually in the Firebase Console.

import 'dart:convert';
import 'dart:io';

const projectId = 'hostel-manager-d0123a';
const apiKey = 'AIzaSyDao5Q-z3lE64SsDjt2JKYdCWS7n5UMciY'; // web API key

const wardenEmail = 'warden@hostel.com';
const wardenPassword = 'Warden@123';
const wardenName = 'Hostel Warden';
const wardenPhone = '+919876543210';

Future<void> main() async {
  print('Creating warden account...');

  // Step 1: Create Firebase Auth account via REST API
  final authUrl = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
  );

  final client = HttpClient();

  final authRequest = await client.postUrl(authUrl);
  authRequest.headers.contentType = ContentType.json;
  authRequest.write(jsonEncode({
    'email': wardenEmail,
    'password': wardenPassword,
    'returnSecureToken': true,
  }));

  final authResponse = await authRequest.close();
  final authBody = jsonDecode(await authResponse.transform(utf8.decoder).join());

  if (authResponse.statusCode != 200) {
    print('Error creating auth account: ${authBody['error']['message']}');
    client.close();
    return;
  }

  final uid = authBody['localId'] as String;
  final idToken = authBody['idToken'] as String;
  print('Auth account created. UID: $uid');

  // Step 2: Create Firestore user document
  final firestoreUrl = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users?documentId=$uid',
  );

  final now = DateTime.now().toUtc().toIso8601String();

  final fsRequest = await client.postUrl(firestoreUrl);
  fsRequest.headers.contentType = ContentType.json;
  fsRequest.headers.set('Authorization', 'Bearer $idToken');
  fsRequest.write(jsonEncode({
    'fields': {
      'name': {'stringValue': wardenName},
      'email': {'stringValue': wardenEmail},
      'role': {'stringValue': 'warden'},
      'phone': {'stringValue': wardenPhone},
      'roomNumber': {'nullValue': null},
      'faceEmbedding': {'nullValue': null},
      'profileImageUrl': {'nullValue': null},
      'createdAt': {'timestampValue': now},
    },
  }));

  final fsResponse = await fsRequest.close();
  final fsBody = jsonDecode(await fsResponse.transform(utf8.decoder).join());

  if (fsResponse.statusCode == 200) {
    print('Warden user document created in Firestore.');
    print('');
    print('=== Warden Credentials ===');
    print('Email:    $wardenEmail');
    print('Password: $wardenPassword');
    print('==========================');
  } else {
    print('Error creating Firestore doc: $fsBody');
  }

  client.close();
}
