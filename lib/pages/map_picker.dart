import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

/// Map picker page: tap to place a marker and press Save (or press back) to return
/// the selected LatLng to the caller. Powered by free OpenStreetMap.
class MapPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  final bool readOnly; // if true, just show a marker and camera

  const MapPickerPage({super.key, this.initialPosition, this.readOnly = false});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _position;
  final MapController _mapController = MapController();
  int _mapStyleIndex = 0; // 0: Voyager, 1: Standard, 2: Topographic

  static const List<String> _tileUrls = [
    'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    'https://tile.opentopomap.org/{z}/{x}/{y}.png',
  ];

  static const List<String> _styleNames = [
    'Voyager (Roads)',
    'Standard OSM',
    'Topographic',
  ];

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition ?? const LatLng(9.145, 40.489673); // Ethiopia center fallback
  }

  void _onTap(TapPosition tapPosition, osm.LatLng point) {
    if (widget.readOnly) return;
    setState(() {
      _position = LatLng(point.latitude, point.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final osmPosition = osm.LatLng(_position.latitude, _position.longitude);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_position);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.readOnly ? 'View Location' : 'Pick Location on Map'),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.layers),
              tooltip: 'Map style',
              onSelected: (value) => setState(() => _mapStyleIndex = value),
              itemBuilder: (_) => [
                for (int i = 0; i < _styleNames.length; i++)
                  PopupMenuItem(
                    value: i,
                    child: Text(_styleNames[i]),
                  ),
              ],
            ),
            if (!widget.readOnly)
              TextButton(
                onPressed: () => Navigator.of(context).pop(_position),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: osmPosition,
                initialZoom: 13,
                onTap: _onTap,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrls[_mapStyleIndex],
                  userAgentPackageName: 'com.example.ethioar_guide',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: osmPosition,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.redAccent,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selected: ${_position.latitude.toStringAsFixed(6)}, ${_position.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
