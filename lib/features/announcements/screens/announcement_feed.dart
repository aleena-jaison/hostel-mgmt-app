import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hostel_manager/features/announcements/models/announcement.dart';
import 'package:hostel_manager/features/announcements/providers/announcement_providers.dart';

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'Just now';
}

class AnnouncementFeed extends ConsumerStatefulWidget {
  const AnnouncementFeed({super.key});

  @override
  ConsumerState<AnnouncementFeed> createState() => _AnnouncementFeedState();
}

class _AnnouncementFeedState extends ConsumerState<AnnouncementFeed> {
  static const _lastSeenKey = 'announcements_last_seen';
  DateTime _lastSeen = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadAndUpdateLastSeen();
  }

  Future<void> _loadAndUpdateLastSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_lastSeenKey) ?? 0;
    setState(() {
      _lastSeen = DateTime.fromMillisecondsSinceEpoch(stored);
    });
    // Update last seen to now so future visits won't show these as unread.
    await prefs.setInt(
      _lastSeenKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool _isUnread(Announcement announcement) {
    return announcement.createdAt.isAfter(_lastSeen);
  }

  @override
  Widget build(BuildContext context) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
      ),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading announcements: $error'),
        ),
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(announcementsProvider);
              await ref.read(announcementsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                final unread = _isUnread(announcement);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (unread)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 12),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                announcement.body,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                timeAgo(announcement.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
