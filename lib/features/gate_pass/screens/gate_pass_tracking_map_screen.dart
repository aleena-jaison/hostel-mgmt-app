import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:hostel_manager/features/gate_pass/providers/gate_pass_providers.dart';
import 'package:hostel_manager/features/gate_pass/services/gate_pass_location_service.dart';

class GatePassTrackingMapScreen extends ConsumerWidget {
  const GatePassTrackingMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(activeGatePassLocationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Gate Pass Tracking')),
      body: locationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (locations) {
          if (locations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No students currently checked out.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return _GatePassMap(locations: locations);
        },
      ),
    );
  }
}

class _GatePassMap extends StatefulWidget {
  final List<StudentGatePassLocation> locations;

  const _GatePassMap({required this.locations});

  @override
  State<_GatePassMap> createState() => _GatePassMapState();
}

class _GatePassMapState extends State<_GatePassMap> {
  final MapController _mapController = MapController();
  StudentGatePassLocation? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = widget.locations.isNotEmpty
        ? LatLng(
            widget.locations.first.latitude, widget.locations.first.longitude)
        : const LatLng(10.0, 76.0);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.colorScheme.primaryContainer,
          child: Text(
            '${widget.locations.length} student(s) checked out being tracked',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hostelmanager.app',
              ),
              MarkerLayer(
                markers: widget.locations.map((loc) {
                  final isSelected =
                      _selectedStudent?.gatePassId == loc.gatePassId;
                  return Marker(
                    point: LatLng(loc.latitude, loc.longitude),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedStudent = loc);
                      },
                      child: Icon(
                        Icons.location_pin,
                        color: isSelected ? Colors.red : Colors.blue,
                        size: isSelected ? 50 : 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (_selectedStudent != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle,
                    size: 40, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedStudent!.studentName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Lat: ${_selectedStudent!.latitude.toStringAsFixed(5)}, '
                        'Lng: ${_selectedStudent!.longitude.toStringAsFixed(5)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Last updated: ${DateFormat('hh:mm a').format(_selectedStudent!.updatedAt)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      setState(() => _selectedStudent = null),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
