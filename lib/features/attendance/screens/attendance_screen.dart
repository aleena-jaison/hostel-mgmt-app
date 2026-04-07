import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import 'package:hostel_manager/features/attendance/models/attendance_record.dart';
import 'package:hostel_manager/features/attendance/providers/attendance_providers.dart';
import 'package:hostel_manager/features/auth/providers/auth_providers.dart';
import 'package:hostel_manager/features/face_auth/providers/face_auth_providers.dart';
import 'package:hostel_manager/features/geofencing/providers/geofence_providers.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isProcessing = false;
  String _statusMessage = '';
  AttendanceRecord? _todayRecord;
  bool _hasCheckedToday = false;

  Future<void> _checkTodayRecord() async {
    if (_hasCheckedToday) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final service = ref.read(attendanceServiceProvider);
    final existing = await service.getTodayAttendance(user.id, today);

    if (mounted) {
      setState(() {
        _todayRecord = existing;
        _hasCheckedToday = true;
      });
    }
  }

  /// Compute whether we're inside the attendance window from live settings.
  bool _isWithinWindow(Map<String, dynamic> settings) {
    final attendanceTime = settings['attendanceTime'] as String? ?? '19:30';
    final windowMinutes =
        (settings['attendanceWindowMinutes'] as num?)?.toInt() ?? 30;

    final parts = attendanceTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    final windowStart = DateTime(now.year, now.month, now.day, hour, minute);
    final windowEnd = windowStart.add(Duration(minutes: windowMinutes));

    return now.isAfter(windowStart) && now.isBefore(windowEnd);
  }

  String _formatWindowTime(Map<String, dynamic> settings) {
    final attendanceTime = settings['attendanceTime'] as String? ?? '19:30';
    final windowMinutes =
        (settings['attendanceWindowMinutes'] as num?)?.toInt() ?? 30;

    final parts = attendanceTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final start = TimeOfDay(hour: hour, minute: minute);
    final endDt = DateTime(
      2000,
      1,
      1,
      hour,
      minute,
    ).add(Duration(minutes: windowMinutes));
    final end = TimeOfDay(hour: endDt.hour, minute: endDt.minute);

    return '${start.format(context)} – ${end.format(context)}';
  }

  Future<void> _markAttendance(Map<String, dynamic> settings) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final service = ref.read(attendanceServiceProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Checking leave status...';
    });

    // Step 1: Check if on approved leave
    final onLeave = await service.isOnApprovedLeave(user.id, DateTime.now());
    if (onLeave) {
      await service.markOnLeave(
        studentId: user.id,
        studentName: user.name,
        date: today,
      );
      final record = await service.getTodayAttendance(user.id, today);
      setState(() {
        _isProcessing = false;
        _todayRecord = record;
        _statusMessage = 'You are on approved leave. Attendance auto-marked.';
      });
      return;
    }

    // Step 2: Check geofence
    setState(() => _statusMessage = 'Checking location...');
    try {
      final locationService = ref.read(locationServiceProvider);

      final center = settings['geofenceCenter'] as Map<String, dynamic>?;
      if (center == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Hostel settings not configured. Contact warden.';
        });
        return;
      }

      final centerLat = (center['lat'] as num).toDouble();
      final centerLng = (center['lng'] as num).toDouble();
      final radius = (settings['geofenceRadiusMeters'] as num).toDouble();

      final position = await locationService.getCurrentPosition();
      final isInside = await locationService.isInsideGeofence(
        position.latitude,
        position.longitude,
        centerLat,
        centerLng,
        radius,
      );

      if (!isInside) {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              'You are not inside the hostel premises. Attendance cannot be marked.';
        });
        return;
      }

      // Step 3: Capture face photo
      setState(() => _statusMessage = 'Please take a selfie...');
      final faceService = ref.read(faceAuthServiceProvider);
      final image = await faceService.captureFace();

      if (image == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Photo capture cancelled.';
        });
        return;
      }

      // Step 4: Verify face
      setState(() => _statusMessage = 'Verifying identity...');
      final hasEnrolled = await faceService.hasEnrolledFace(user.id);

      if (hasEnrolled) {
        final verified = await faceService.verifyFace(user.id, image);
        if (!verified) {
          setState(() {
            _isProcessing = false;
            _statusMessage =
                'Face verification failed. Please try again or contact the warden.';
          });
          return;
        }
      }

      // Step 5: Upload photo and mark attendance
      setState(() => _statusMessage = 'Uploading photo...');
      final photoBytes = await image.readAsBytes();
      final photoUrl = await service.uploadAttendancePhoto(
        user.id,
        today,
        photoBytes,
      );

      await service.markPresent(
        studentId: user.id,
        studentName: user.name,
        date: today,
        photoUrl: photoUrl,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final record = await service.getTodayAttendance(user.id, today);
      setState(() {
        _isProcessing = false;
        _todayRecord = record;
        _statusMessage = 'Attendance marked successfully!';
      });
    } on LocationServiceDisabledException {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Please enable location services.';
      });
    } on PermissionDeniedException {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Location permission denied. Please grant access.';
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(hostelSettingsStreamProvider);

    // Check today's record once
    _checkTodayRecord();

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading settings: $e')),
      data: (settings) {
        if (settings == null) {
          return const Center(child: Text('Hostel settings not configured.'));
        }

        final withinWindow = _isWithinWindow(settings);
        final windowTimeStr = _formatWindowTime(settings);

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIcon(theme),
                const SizedBox(height: 24),

                Text('Daily Attendance', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),

                // Show live attendance window time
                Chip(
                  avatar: Icon(
                    withinWindow ? Icons.check_circle : Icons.schedule,
                    size: 18,
                    color: withinWindow ? Colors.green : Colors.orange,
                  ),
                  label: Text(
                    'Window: $windowTimeStr',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 24),

                // Already marked today
                if (_todayRecord != null) ...[
                  _buildAttendanceCard(theme),
                ]
                // Not yet marked
                else ...[
                  if (!withinWindow) ...[
                    const Icon(Icons.schedule, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Attendance window is not open yet.\nCome back at $windowTimeStr.',
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    if (_statusMessage.isNotEmpty) ...[
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _statusMessage.contains('failed') ||
                                  _statusMessage.contains('not inside') ||
                                  _statusMessage.contains('Error')
                              ? Colors.red
                              : _statusMessage.contains('success')
                              ? Colors.green
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_isProcessing)
                      const CircularProgressIndicator()
                    else
                      FilledButton.icon(
                        onPressed: () => _markAttendance(settings),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Mark Attendance'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    if (_todayRecord != null) {
      final status = _todayRecord!.status;
      return Icon(
        status == AttendanceStatus.present
            ? Icons.check_circle
            : status == AttendanceStatus.onLeave
            ? Icons.flight_takeoff
            : Icons.cancel,
        size: 80,
        color: status == AttendanceStatus.present
            ? Colors.green
            : status == AttendanceStatus.onLeave
            ? Colors.blue
            : Colors.red,
      );
    }
    return Icon(
      Icons.face_2_outlined,
      size: 80,
      color: theme.colorScheme.primary,
    );
  }

  Widget _buildAttendanceCard(ThemeData theme) {
    final record = _todayRecord!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              record.status.label,
              style: theme.textTheme.titleLarge?.copyWith(
                color: record.status == AttendanceStatus.present
                    ? Colors.green
                    : record.status == AttendanceStatus.onLeave
                    ? Colors.blue
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (record.markedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Marked at ${DateFormat('hh:mm a').format(record.markedAt!)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (record.photoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  record.photoUrl!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
