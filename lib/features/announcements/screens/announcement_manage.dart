import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hostel_manager/features/announcements/models/announcement.dart';
import 'package:hostel_manager/features/announcements/providers/announcement_providers.dart';

class AnnouncementManage extends ConsumerWidget {
  const AnnouncementManage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Announcements'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              return Dismissible(
                key: Key(announcement.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: colorScheme.error,
                  child: Icon(Icons.delete, color: colorScheme.onError),
                ),
                confirmDismiss: (_) =>
                    _confirmDelete(context, announcement.title),
                onDismissed: (_) {
                  ref
                      .read(announcementServiceProvider)
                      .deleteAnnouncement(announcement.id);
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      announcement.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          announcement.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMd().add_jm().format(announcement.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: colorScheme.error),
                      onPressed: () async {
                        final confirmed =
                            await _confirmDelete(context, announcement.title);
                        if (confirmed == true) {
                          ref
                              .read(announcementServiceProvider)
                              .deleteAnnouncement(announcement.id);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Announcement'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a body';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final announcement = Announcement(
                id: '',
                title: titleController.text.trim(),
                body: bodyController.text.trim(),
                createdBy: '', // Should be set to the current user's ID
                createdAt: DateTime.now(),
              );

              ref
                  .read(announcementServiceProvider)
                  .createAnnouncement(announcement);

              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
