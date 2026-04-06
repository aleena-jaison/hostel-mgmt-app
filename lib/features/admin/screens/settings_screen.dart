import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hostel_manager/features/geofencing/providers/geofence_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostelNameController = TextEditingController();
  final _centerLatController = TextEditingController();
  final _centerLngController = TextEditingController();
  final _radiusController = TextEditingController();
  final _checkinIntervalController = TextEditingController();
  final _attendanceWindowController = TextEditingController();

  TimeOfDay _curfewStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _curfewEnd = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _attendanceTime = const TimeOfDay(hour: 19, minute: 30);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('hostelSettings')
          .get();

      final settings = doc.data();
      if (settings != null) {
        _hostelNameController.text = settings['hostelName'] as String? ?? '';

        // Geofence center
        final center = settings['geofenceCenter'] as Map<String, dynamic>?;
        if (center != null) {
          _centerLatController.text = (center['lat'] as num?)?.toString() ?? '';
          _centerLngController.text = (center['lng'] as num?)?.toString() ?? '';
        }

        _radiusController.text =
            (settings['geofenceRadiusMeters'] as num?)?.toString() ?? '500';
        _checkinIntervalController.text =
            (settings['checkinIntervalMinutes'] as num?)?.toString() ?? '15';
        _attendanceWindowController.text =
            (settings['attendanceWindowMinutes'] as num?)?.toString() ?? '30';

        final curfewStartStr = settings['curfewStart'] as String?;
        if (curfewStartStr != null) _curfewStart = _parseTime(curfewStartStr);

        final curfewEndStr = settings['curfewEnd'] as String?;
        if (curfewEndStr != null) _curfewEnd = _parseTime(curfewEndStr);

        final attendanceStr = settings['attendanceTime'] as String?;
        if (attendanceStr != null) _attendanceTime = _parseTime(attendanceStr);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('hostelSettings')
          .set({
        'hostelName': _hostelNameController.text.trim(),
        'curfewStart': _formatTime(_curfewStart),
        'curfewEnd': _formatTime(_curfewEnd),
        'geofenceCenter': {
          'lat': double.tryParse(_centerLatController.text.trim()) ?? 0.0,
          'lng': double.tryParse(_centerLngController.text.trim()) ?? 0.0,
        },
        'geofenceRadiusMeters':
            int.tryParse(_radiusController.text.trim()) ?? 500,
        'checkinIntervalMinutes':
            int.tryParse(_checkinIntervalController.text.trim()) ?? 15,
        'attendanceTime': _formatTime(_attendanceTime),
        'attendanceWindowMinutes':
            int.tryParse(_attendanceWindowController.text.trim()) ?? 30,
      });

      ref.invalidate(hostelSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime({
    required TimeOfDay current,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) setState(() => onPicked(picked));
  }

  @override
  void dispose() {
    _hostelNameController.dispose();
    _centerLatController.dispose();
    _centerLngController.dispose();
    _radiusController.dispose();
    _checkinIntervalController.dispose();
    _attendanceWindowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hostel Settings',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),

            // Hostel Name
            TextFormField(
              controller: _hostelNameController,
              decoration: const InputDecoration(
                labelText: 'Hostel Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Curfew
            Text('Curfew Hours',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(_curfewStart.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(
                      current: _curfewStart,
                      onPicked: (t) => _curfewStart = t,
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text(_curfewEnd.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(
                      current: _curfewEnd,
                      onPicked: (t) => _curfewEnd = t,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Attendance
            Text('Attendance Settings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Attendance Time'),
                    subtitle: Text(_attendanceTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(
                      current: _attendanceTime,
                      onPicked: (t) => _attendanceTime = t,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _attendanceWindowController,
                    decoration: const InputDecoration(
                      labelText: 'Window (minutes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Geofence
            Text('Geofence Settings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _centerLatController,
                    decoration: const InputDecoration(
                      labelText: 'Center Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _centerLngController,
                    decoration: const InputDecoration(
                      labelText: 'Center Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _radiusController,
                    decoration: const InputDecoration(
                      labelText: 'Radius (meters)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _checkinIntervalController,
                    decoration: const InputDecoration(
                      labelText: 'Check-in Interval (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
