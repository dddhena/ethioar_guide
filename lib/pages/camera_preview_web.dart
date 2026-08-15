// Web fallback: use file input (capture photo) + nearby overlay (no HtmlElementView)
import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'dart:js_util' as js_util;

import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../services/firestore_service.dart';
import '../models/landmark.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({Key? key}) : super(key: key);

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  String? _imageUrl;
  String _status = 'Ready';
  List<Landmark> _nearby = [];
  bool _loadingNearby = false;
  double? _currentLat;
  double? _currentLon;

  Future<void> _takePhoto() async {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    // Use attribute for capture to avoid SDK differences (some platforms don't expose a capture setter)
    input.setAttribute('capture', 'environment');
    input.click();
    input.onChange.listen((_) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final url = html.Url.createObjectUrlFromBlob(file);
        if (!mounted) return;
        setState(() {
          // Revoke previous object URL if present to avoid leaks
          if (_imageUrl != null) html.Url.revokeObjectUrl(_imageUrl!);
          _imageUrl = url;
        });
      }
    });
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) + math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  Future<void> _showNearby() async {
    if (!mounted) return;
    setState(() {
      _loadingNearby = true;
    });
    try {
      // get current position via browser geolocation (callback-based API)
      final geo = html.window.navigator.geolocation;
      if (geo == null) {
        if (!mounted) return;
        setState(() {
          _status = 'Geolocation unavailable';
          _loadingNearby = false;
        });
        return;
      }

      // Modern dart:html exposes getCurrentPosition as a Future-returning API in some SDKs.
      // Call it directly and await the result; fall back to the callback approach if needed.
      html.Geoposition pos;
      try {
        // try awaiting the Future-returning API
        pos = await geo.getCurrentPosition();
      } catch (_) {
        // fallback: use a Completer with callback-based API
        final completer = Completer<html.Geoposition>();
        try {
          // Use js interop to call the callback-based API when the static signature isn't available.
          js_util.callMethod(
            geo,
            'getCurrentPosition',
            [
              js_util.allowInterop((p) => completer.complete(p)),
              js_util.allowInterop((err) => completer.completeError(err)),
            ],
          );
        } catch (e) {
          completer.completeError(e);
        }
        pos = await completer.future;
      }

      final lat = (pos.coords?.latitude ?? 0.0).toDouble();
      final lon = (pos.coords?.longitude ?? 0.0).toDouble();
      _currentLat = lat;
      _currentLon = lon;

      final list = await FirestoreService().fetchLandmarks();
      final nearby = <Landmark>[];
      for (final lm in list) {
        final d = _distanceKm(lat, lon, lm.latitude.toDouble(), lm.longitude.toDouble());
        if (d <= 50.0) { // within 50 km
          nearby.add(lm);
        }
      }

      if (!mounted) return;
      setState(() {
        _nearby = nearby;
        _status = nearby.isEmpty ? 'No nearby landmarks found.' : 'Nearby landmarks loaded';
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

  void _openInMaps(Landmark landmark) {
    final lat = landmark.latitude;
    final lon = landmark.longitude;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
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
      title: 'AR Camera (Web fallback)',
      body: Column(
        children: [
          Expanded(
            child: _imageUrl == null
                ? Center(child: Text(_status))
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  onPressed: _takePhoto,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Show Nearby'),
                  onPressed: _showNearby,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Historical Photo'),
                  onPressed: () async {
                    // placeholder: show a sample historical photo fetched from ar_contents or storage
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Historical photo overlay (web fallback)'),
                            const SizedBox(height: 8),
                            Image.network(
                              'https://via.placeholder.com/300x200.png?text=Historical+Photo',
                              errorBuilder: (context, error, stack) => const SizedBox(
                                width: 300,
                                height: 200,
                                child: Center(child: Icon(Icons.broken_image)),
                              ),
                            ),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (_nearby.isNotEmpty)
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearby.length,
                itemBuilder: (context, i) {
                  final lm = _nearby[i];
                  final distance = (_currentLat == null || _currentLon == null)
                      ? null
                      : _distanceKm(_currentLat!, _currentLon!, lm.latitude.toDouble(), lm.longitude.toDouble());
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: SizedBox(
                      width: 240,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lm.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(lm.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            if (distance != null)
                              Text('${distance.toStringAsFixed(1)} km away', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Coords: ${lm.latitude.toStringAsFixed(3)}, ${lm.longitude.toStringAsFixed(3)}', style: const TextStyle(fontSize: 11)),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _openInMaps(lm),
                                icon: const Icon(Icons.directions),
                                label: const Text('Navigate'),
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
    );
  }
}
