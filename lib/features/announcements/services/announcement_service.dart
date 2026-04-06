import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hostel_manager/features/announcements/models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection('announcements');

  /// Adds a new announcement to the `announcements` collection.
  Future<void> createAnnouncement(Announcement announcement) async {
    await _collection.add(announcement.toMap());
  }

  /// Returns a real-time stream of all announcements ordered by
  /// [createdAt] descending (newest first).
  Stream<List<Announcement>> getAnnouncements() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromFirestore(doc))
            .toList());
  }

  /// Deletes the announcement with the given [id].
  Future<void> deleteAnnouncement(String id) async {
    await _collection.doc(id).delete();
  }
}
