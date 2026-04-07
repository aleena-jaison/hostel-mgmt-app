import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hostel_manager/features/attendance/models/attendance_record.dart';
import 'package:hostel_manager/features/attendance/providers/attendance_providers.dart';

class AttendanceManageScreen extends ConsumerStatefulWidget {
  const AttendanceManageScreen({super.key});

  @override
  ConsumerState<AttendanceManageScreen> createState() =>
      _AttendanceManageScreenState();
}

class _AttendanceManageScreenState
    extends ConsumerState<AttendanceManageScreen> {
  late DateTime _selectedDate;
  late String _dateStr;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateStr = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Date picker header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Attendance',
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              ActionChip(
                avatar: const Icon(Icons.calendar_today, size: 18),
                label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                onPressed: _pickDate,
              ),
            ],
          ),
        ),

        // Summary row
        _AttendanceSummary(date: _dateStr),

        const Divider(),

        // Records list
        Expanded(
          child: _AttendanceList(date: _dateStr),
        ),
      ],
    );
  }
}

class _AttendanceSummary extends ConsumerWidget {
  final String date;
  const _AttendanceSummary({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(todayAttendanceProvider(date));
    final theme = Theme.of(context);

    return recordsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.error)),
      ),
      data: (records) {
        final present =
            records.where((r) => r.status == AttendanceStatus.present).length;
        final onLeave =
            records.where((r) => r.status == AttendanceStatus.onLeave).length;
        final total = records.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryChip(
                    label: 'Present', count: present, color: Colors.green),
                const SizedBox(width: 12),
                _SummaryChip(
                    label: 'On Leave', count: onLeave, color: Colors.blue),
                const SizedBox(width: 12),
                _SummaryChip(
                    label: 'Total Marked', count: total, color: Colors.grey),
                const SizedBox(width: 12),
                // Count of students who haven't marked
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final totalStudents = snap.data!.docs.length;
                    final absent = totalStudents - total;
                    return _SummaryChip(
                      label: 'Absent',
                      count: absent < 0 ? 0 : absent,
                      color: Colors.red,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      label: Text(label),
    );
  }
}

class _AttendanceList extends ConsumerWidget {
  final String date;
  const _AttendanceList({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(todayAttendanceProvider(date));
    final theme = Theme.of(context);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error loading attendance: $e'),
      ),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_reg, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No attendance records for this date',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            return Card(
              child: ListTile(
                leading: record.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(record.photoUrl!),
                      )
                    : CircleAvatar(
                        backgroundColor: record.status ==
                                AttendanceStatus.onLeave
                            ? Colors.blue[100]
                            : Colors.green[100],
                        child: Icon(
                          record.status == AttendanceStatus.onLeave
                              ? Icons.flight_takeoff
                              : Icons.person,
                          color: record.status == AttendanceStatus.onLeave
                              ? Colors.blue
                              : Colors.green,
                        ),
                      ),
                title: Text(record.studentName),
                subtitle: record.markedAt != null
                    ? Text(
                        'Marked at ${DateFormat('hh:mm a').format(record.markedAt!)}')
                    : null,
                trailing: Chip(
                  label: Text(
                    record.status.label,
                    style: TextStyle(
                      color: record.status == AttendanceStatus.present
                          ? Colors.green
                          : record.status == AttendanceStatus.onLeave
                              ? Colors.blue
                              : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: record.photoUrl != null
                    ? () => _showPhotoDialog(context, record)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  void _showPhotoDialog(BuildContext context, AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.studentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.photoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  record.photoUrl!,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, __) => Container(
                    height: 250,
                    width: 250,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Image failed to load.\nConfigure CORS on storage bucket.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (record.markedAt != null)
              Text(
                  'Time: ${DateFormat('hh:mm a').format(record.markedAt!)}'),
            if (record.latitude != null)
              Text(
                'Location: ${record.latitude!.toStringAsFixed(4)}, ${record.longitude!.toStringAsFixed(4)}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
