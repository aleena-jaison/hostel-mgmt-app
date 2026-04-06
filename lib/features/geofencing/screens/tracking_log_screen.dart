import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/geofencing/providers/geofence_providers.dart';
import 'package:intl/intl.dart';

class TrackingLogScreen extends ConsumerStatefulWidget {
  const TrackingLogScreen({super.key});

  @override
  ConsumerState<TrackingLogScreen> createState() => _TrackingLogScreenState();
}

class _TrackingLogScreenState extends ConsumerState<TrackingLogScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final violationsAsync = ref.watch(violationsProvider);
    final dateFormat = DateFormat('MMM dd, yyyy  hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Violation Tracking'),
      ),
      body: Column(
        children: [
          // Date filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? 'Showing: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}'
                        : 'Showing: All dates',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedDate = null);
                    },
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear filter',
                  ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Filter'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Violations list
          Expanded(
            child: violationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (violations) {
                // Apply client-side date filter
                final filtered = _selectedDate != null
                    ? violations.where((v) {
                        final ts = v['timestamp'] as Timestamp?;
                        if (ts == null) return false;
                        final dt = ts.toDate();
                        return dt.year == _selectedDate!.year &&
                            dt.month == _selectedDate!.month &&
                            dt.day == _selectedDate!.day;
                      }).toList()
                    : violations;

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text('No violations found.'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final violation = filtered[index];
                    final timestamp = violation['timestamp'] as Timestamp?;
                    final studentName =
                        violation['studentName'] as String? ?? 'Unknown';
                    final studentId =
                        violation['studentId'] as String? ?? 'N/A';
                    final lat = (violation['latitude'] as num?)?.toDouble();
                    final lng = (violation['longitude'] as num?)?.toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    studentName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Outside',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Student ID: $studentId'),
                            if (timestamp != null)
                              Text(
                                'Time: ${dateFormat.format(timestamp.toDate())}',
                              ),
                            if (lat != null && lng != null)
                              Text(
                                'Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
