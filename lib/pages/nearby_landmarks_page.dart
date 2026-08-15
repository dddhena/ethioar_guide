import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:html' as html;

import '../models/landmark.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/snackbar_helper.dart';
import 'camera_preview.dart';
import 'map_picker.dart';

class NearbyLandmarksPage extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialLocationName;

  const NearbyLandmarksPage({
    super.key,
    this.initialLocation,
    this.initialLocationName,
  });

  @override
  State<NearbyLandmarksPage> createState() => _NearbyLandmarksPageState();
}

class _NearbyLandmarksPageState extends State<NearbyLandmarksPage> {
  final FirestoreService _fs = FirestoreService();

  // Current reference location
  double _currentLat = 9.0320; // Default Addis Ababa
  double _currentLon = 38.7469;
  String _locationName = 'Addis Ababa';
  bool _isGpsLocation = false;

  // Filters and state
  double? _selectedRadiusKm = 150.0; // Default 150 km
  bool _loading = true;
  List<Landmark> _allLandmarks = [];
  List<NearbyLandmark> _nearbyLandmarks = [];

  final List<double?> _radiusOptions = [25.0, 50.0, 150.0, 500.0, null];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLat = widget.initialLocation!.latitude;
      _currentLon = widget.initialLocation!.longitude;
      _locationName = widget.initialLocationName ?? 'Selected Location';
    } else {
      _detectCurrentLocation();
    }
    _loadLandmarks();
  }

  Future<void> _detectCurrentLocation() async {
    final pos = await LocationService.getCurrentPositionWeb();
    if (pos != null && mounted) {
      setState(() {
        _currentLat = pos['latitude']!;
        _currentLon = pos['longitude']!;
        _locationName = 'My Current GPS';
        _isGpsLocation = true;
      });
      _recalculateNearby();
    }
  }

  Future<void> _loadLandmarks() async {
    setState(() => _loading = true);
    _allLandmarks = await _fs.fetchLandmarks();
    _recalculateNearby();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _recalculateNearby() {
    _nearbyLandmarks = LocationService.getNearbyLandmarks(
      currentLat: _currentLat,
      currentLon: _currentLon,
      landmarks: _allLandmarks,
      maxRadiusKm: _selectedRadiusKm,
    );
  }

  void _openGoogleMapsNavigation(double lat, double lon) {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      SnackbarHelper.show(context, 'Navigating to: $lat, $lon');
    }
  }

  void _showLocationPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choose Reference Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade50,
                    child: Icon(Icons.my_location, color: Colors.teal.shade800),
                  ),
                  title: const Text('Use Live Device GPS', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Detect your current location via browser/phone GPS'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _detectCurrentLocation();
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.map, color: Colors.blue.shade800),
                  ),
                  title: const Text('Pick Custom Point on Map', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Tap any location on the map to find nearby landmarks'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final selected = await Navigator.of(context).push<LatLng>(
                      MaterialPageRoute(
                        builder: (_) => MapPickerPage(
                          initialPosition: LatLng(_currentLat, _currentLon),
                        ),
                      ),
                    );
                    if (selected != null && mounted) {
                      setState(() {
                        _currentLat = selected.latitude;
                        _currentLon = selected.longitude;
                        _locationName = 'Custom Map Pin';
                        _isGpsLocation = false;
                        _recalculateNearby();
                      });
                    }
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: Text(
                    'Explore Ethiopian Cities:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: LocationService.ethiopianCities.length,
                    itemBuilder: (context, i) {
                      final city = LocationService.ethiopianCities[i];
                      final isSelected = _locationName == city.name;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.location_city,
                          color: isSelected ? Colors.teal : Colors.grey.shade600,
                        ),
                        title: Text(city.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(city.description),
                        trailing: Text(
                          '${city.latitude.toStringAsFixed(2)}, ${city.longitude.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          setState(() {
                            _currentLat = city.latitude;
                            _currentLon = city.longitude;
                            _locationName = city.name;
                            _isGpsLocation = false;
                            _recalculateNearby();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nearby Landmarks',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _loadLandmarks,
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationBanner(),
                const SizedBox(height: 12),
                _buildRadiusFilterBar(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _nearbyLandmarks.isEmpty
                            ? 'No landmarks in selected range'
                            : 'Found ${_nearbyLandmarks.length} landmark${_nearbyLandmarks.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (_nearbyLandmarks.isNotEmpty)
                        Text(
                          'Sorted by distance',
                          style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _nearbyLandmarks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _nearbyLandmarks.length,
                          itemBuilder: (context, i) {
                            return _buildNearbyLandmarkCard(_nearbyLandmarks[i]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationBanner() {
    return Card(
      elevation: 2,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade700,
              radius: 20,
              child: Icon(
                _isGpsLocation ? Icons.my_location : Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Exploring near: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        _locationName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'GPS: ${_currentLat.toStringAsFixed(4)}, ${_currentLon.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                foregroundColor: Colors.teal.shade800,
                side: BorderSide(color: Colors.teal.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Change', style: TextStyle(fontSize: 12)),
              onPressed: _showLocationPickerSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _radiusOptions.map((radius) {
          final isSelected = _selectedRadiusKm == radius;
          final label = radius == null ? 'All (Any Distance)' : '< ${radius.toInt()} km';

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: Colors.teal.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.teal.shade900,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              backgroundColor: Colors.grey.shade100,
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedRadiusKm = radius;
                    _recalculateNearby();
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNearbyLandmarkCard(NearbyLandmark item) {
    final lm = item.landmark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lm.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lm.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedDistance,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Direction: ${item.direction}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${lm.latitude.toStringAsFixed(3)}, ${lm.longitude.toStringAsFixed(3)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.explore, size: 14),
                  label: const Text('AR View', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CameraPreviewPage()),
                    );
                  },
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.map, size: 14),
                  label: const Text('Map', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapPickerPage(
                          initialPosition: LatLng(lm.latitude, lm.longitude),
                          readOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.directions, size: 14),
                  label: const Text('Navigate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _openGoogleMapsNavigation(lm.latitude, lm.longitude),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No landmarks found within ${_selectedRadiusKm != null ? "${_selectedRadiusKm!.toInt()} km" : "range"} of $_locationName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try expanding the distance radius or switch to a major historic city like Lalibela, Gondar, or Aksum.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRadiusKm = null; // Show all
                      _recalculateNearby();
                    });
                  },
                  child: const Text('Show All Landmarks'),
                ),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _currentLat = 12.0319;
                      _currentLon = 39.0476;
                      _locationName = 'Lalibela';
                      _isGpsLocation = false;
                      _selectedRadiusKm = 150.0;
                      _recalculateNearby();
                    });
                  },
                  child: const Text('Explore Lalibela'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
