import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hostel_manager/core/constants/enums.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? roomNumber;
  final String phone;
  final List<double>? faceEmbedding;
  final String? profileImageUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roomNumber,
    required this.phone,
    this.faceEmbedding,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      role: UserRole.fromString(data['role'] as String),
      roomNumber: data['roomNumber'] as String?,
      phone: data['phone'] as String,
      faceEmbedding: (data['faceEmbedding'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'roomNumber': roomNumber,
      'phone': phone,
      'faceEmbedding': faceEmbedding,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
