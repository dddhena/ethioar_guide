import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map picker page: tap to place a marker and press Save (or press back) to return
/// the selected LatLng to the caller.
class MapPickerPage extends StatefulWidget {
  final LatLng? initialPosition;
  final bool readOnly; // if true, just show a marker and camera

  const MapPickerPage({super.key, this.initialPosition, this.readOnly = false});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _position;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition ?? const LatLng(9.145, 40.489673); // Ethiopia center fallback
  }

  void _onTap(LatLng pos) {
    if (widget.readOnly) return;
    setState(() => _position = pos);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When user presses back, return the current selection.
        Navigator.of(context).pop(_position);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.readOnly ? 'View Location' : 'Pick Location on Map'),
          actions: [
            PopupMenuButton<MapType>(
              icon: const Icon(Icons.layers),
              tooltip: 'Map style',
              onSelected: (value) => setState(() => _mapType = value),
              itemBuilder: (_) => const [
                PopupMenuItem(value: MapType.normal, child: Text('Normal')),
                PopupMenuItem(value: MapType.satellite, child: Text('Satellite')),
                PopupMenuItem(value: MapType.terrain, child: Text('Terrain')),
                PopupMenuItem(value: MapType.hybrid, child: Text('Hybrid')),
              ],
            ),
            if (!widget.readOnly)
              TextButton(
                onPressed: () => Navigator.of(context).pop(_position),
                child: const Text('Save', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _position, zoom: 12),
              mapType: _mapType,
              onTap: _onTap,
              markers: {
                Marker(markerId: const MarkerId('selected'), position: _position),
              },
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Selected: ${_position.latitude.toStringAsFixed(6)}, ${_position.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
