import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/announcements/models/announcement.dart';
import 'package:hostel_manager/features/announcements/services/announcement_service.dart';

/// Provides a singleton instance of [AnnouncementService].
final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService();
});

/// Streams the list of announcements in real-time, ordered by creation
/// date descending.
final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  final service = ref.watch(announcementServiceProvider);
  return service.getAnnouncements();
});
