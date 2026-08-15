// Web fallback: use file input (capture photo) + nearby overlay (no HtmlElementView)
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'nearby_landmarks_page.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({super.key});

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  String? _imageUrl;
  String _status = 'Ready';
  List<NearbyLandmark> _nearby = [];
  bool _loadingNearby = false;
  double _currentLat = 9.0320; // Default Addis Ababa
  double _currentLon = 38.7469;
  String _locationLabel = 'Addis Ababa';
  double? _radiusKm = 150.0;

  Future<void> _takePhoto() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.setAttribute('capture', 'environment');
    input.click();
    input.onChange.listen((_) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final url = html.Url.createObjectUrlFromBlob(file);
        if (!mounted) return;
        setState(() {
          if (_imageUrl != null) html.Url.revokeObjectUrl(_imageUrl!);
          _imageUrl = url;
        });
      }
    });
  }

  Future<void> _showNearby() async {
    if (!mounted) return;
    setState(() {
      _loadingNearby = true;
    });

    try {
      // Try fetching browser geolocation
      final pos = await LocationService.getCurrentPositionWeb();
      if (pos != null) {
        _currentLat = pos['latitude']!;
        _currentLon = pos['longitude']!;
        _locationLabel = 'Current GPS';
      }

      final allLandmarks = await FirestoreService().fetchLandmarks();
      var list = LocationService.getNearbyLandmarks(
        currentLat: _currentLat,
        currentLon: _currentLon,
        landmarks: allLandmarks,
        maxRadiusKm: _radiusKm,
      );

      // If no landmarks in tight radius, show nearest available
      if (list.isEmpty && allLandmarks.isNotEmpty) {
        list = LocationService.getNearbyLandmarks(
          currentLat: _currentLat,
          currentLon: _currentLon,
          landmarks: allLandmarks,
          maxRadiusKm: null,
        );
      }

      if (!mounted) return;
      setState(() {
        _nearby = list;
        _status = list.isEmpty
            ? 'No nearby landmarks found.'
            : 'Found ${list.length} nearby landmarks ($_locationLabel)';
        _loadingNearby = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Nearby error: $e';
        _loadingNearby = false;
      });
    }
  }

  void _openInMaps(double lat, double lon) {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
    html.window.open(url, '_blank');
  }

  @override
  void dispose() {
    if (_imageUrl != null) html.Url.revokeObjectUrl(_imageUrl!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AR Camera & Nearby',
      actions: [
        IconButton(
          icon: const Icon(Icons.near_me),
          tooltip: 'Open Nearby Explorer',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NearbyLandmarksPage()),
          ),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: _imageUrl == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(_status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Text(
                          'Capture a photo or tap "Show Nearby" to locate Ethiopian landmarks around you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
          ),
          const SizedBox(height: 8),
          if (_loadingNearby) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  onPressed: _takePhoto,
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                  icon: const Icon(Icons.near_me),
                  label: const Text('Show Nearby'),
                  onPressed: _showNearby,
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade800),
                  icon: const Icon(Icons.explore),
                  label: const Text('Nearby Explorer'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NearbyLandmarksPage()),
                  ),
                ),
              ],
            ),
          ),
          if (_nearby.isNotEmpty)
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '📍 Nearby Landmarks (${_nearby.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NearbyLandmarksPage()),
                          ),
                          child: Text(
                            'View all →',
                            style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearby.length,
                      itemBuilder: (context, i) {
                        final item = _nearby[i];
                        final lm = item.landmark;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: SizedBox(
                            width: 250,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lm.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.teal.shade200),
                                        ),
                                        child: Text(
                                          item.formattedDistance,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lm.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${item.direction} • ${lm.latitude.toStringAsFixed(2)}, ${lm.longitude.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal.shade700,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                      ),
                                      onPressed: () => _openInMaps(lm.latitude, lm.longitude),
                                      icon: const Icon(Icons.directions, size: 14),
                                      label: const Text('Directions', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
