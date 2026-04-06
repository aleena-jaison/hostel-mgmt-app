import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String createdBy;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdBy,
    required this.createdAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] as String,
      body: data['body'] as String,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
