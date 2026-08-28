import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/routing_service.dart';
import '../../theme/ethio_theme.dart';

class RouteMapViewer extends StatefulWidget {
  final List<LatLng> polylinePoints;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng>? waypoints;
  final LatLng? animatedMarkerPosition;
  final double animatedMarkerHeading;
  final TravelMode travelMode;
  final bool isPreviewMode;
  final String startLabel;
  final String destinationLabel;
  final List<String>? waypointLabels;
  final VoidCallback? onRecenter;

  const RouteMapViewer({
    super.key,
    required this.polylinePoints,
    required this.startLocation,
    required this.endLocation,
    this.waypoints,
    this.animatedMarkerPosition,
    this.animatedMarkerHeading = 0.0,
    required this.travelMode,
    this.isPreviewMode = true,
    this.startLabel = 'Starting Point',
    this.destinationLabel = 'Destination',
    this.waypointLabels,
    this.onRecenter,
  });

  @override
  State<RouteMapViewer> createState() => _RouteMapViewerState();
}

class _RouteMapViewerState extends State<RouteMapViewer> {
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;

  @override
  void didUpdateWidget(covariant RouteMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Follow animated marker if active
    if (widget.animatedMarkerPosition != null &&
        widget.animatedMarkerPosition != oldWidget.animatedMarkerPosition &&
        _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(widget.animatedMarkerPosition!),
      );
    } else if (widget.polylinePoints != oldWidget.polylinePoints && _mapController != null) {
      _fitBounds();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_mapController == null) return;
    final points = widget.polylinePoints.isNotEmpty
        ? widget.polylinePoints
        : [widget.startLocation, widget.endLocation];

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 65.0),
    );
  }

  void _recenterRoute() {
    widget.onRecenter?.call();
    _fitBounds();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    final startTitle = widget.startLabel.isNotEmpty ? widget.startLabel : 'Starting Point';
    final destTitle = widget.destinationLabel.isNotEmpty ? widget.destinationLabel : 'Destination';

    // 1. Start Marker (Blue / Azure)
    markers.add(
      Marker(
        markerId: const MarkerId('start_point'),
        position: widget.startLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
          title: startTitle,
          snippet: 'Journey Departure Point',
        ),
      ),
    );

    // 2. Destination Marker (Red)
    markers.add(
      Marker(
        markerId: const MarkerId('destination_point'),
        position: widget.endLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        infoWindow: InfoWindow(
          title: destTitle,
          snippet: 'Arrival Destination',
        ),
      ),
    );

    // 3. Intermediate Waypoint Markers (Orange)
    if (widget.waypoints != null) {
      for (int i = 0; i < widget.waypoints!.length; i++) {
        final label = (widget.waypointLabels != null && i < widget.waypointLabels!.length)
            ? widget.waypointLabels![i]
            : 'Tour Stop ${i + 1}';

        markers.add(
          Marker(
            markerId: MarkerId('waypoint_$i'),
            position: widget.waypoints![i],
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: label,
              snippet: 'Stop #${i + 1}',
            ),
          ),
        );
      }
    }

    // 4. Moving Animated Marker (Green / Yellow Vehicle / Walker Marker)
    if (widget.animatedMarkerPosition != null) {
      final headingDeg = (widget.animatedMarkerHeading * 180 / math.pi + 360) % 360;
      markers.add(
        Marker(
          markerId: const MarkerId('animated_traveler'),
          position: widget.animatedMarkerPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.travelMode == TravelMode.driving
                ? BitmapDescriptor.hueYellow
                : BitmapDescriptor.hueGreen,
          ),
          rotation: headingDeg,
          zIndex: 10,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: widget.travelMode == TravelMode.driving ? '🚗 Driving Preview' : '🚶 Walking Preview',
            snippet: 'Estimated speed: ${widget.travelMode == TravelMode.driving ? "35 km/h" : "4.8 km/h"}',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    final points = widget.polylinePoints.isNotEmpty
        ? widget.polylinePoints
        : [widget.startLocation, widget.endLocation];

    // Primary route road line (safe for both Web and Mobile)
    polylines.add(
      Polyline(
        polylineId: const PolylineId('active_route'),
        points: points,
        color: widget.travelMode == TravelMode.driving
            ? const Color(0xFF1E6B3B)
            : const Color(0xFFC4784A),
        width: 6,
      ),
    );

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    final midLat = (widget.startLocation.latitude + widget.endLocation.latitude) / 2;
    final midLon = (widget.startLocation.longitude + widget.endLocation.longitude) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // 1. Real GoogleMap Widget
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(midLat, midLon),
              zoom: 14.5,
            ),
            mapType: _mapType,
            onMapCreated: _onMapCreated,
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // 2. Mode Header Badge (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.travelMode == TravelMode.driving
                        ? Icons.directions_car_rounded
                        : Icons.directions_walk_rounded,
                    color: Colors.amberAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isPreviewMode
                        ? 'ROUTE PREVIEW MAP'
                        : 'REAL-TIME NAVIGATION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Map Type Selector Menu (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: PopupMenuButton<MapType>(
              initialValue: _mapType,
              tooltip: 'Change Map Style',
              onSelected: (type) => setState(() => _mapType = type),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EthioColors.divider),
                  boxShadow: const [
                    BoxShadow(color: EthioColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getMapTypeIcon(_mapType), size: 16, color: EthioColors.forest),
                    const SizedBox(width: 6),
                    Text(
                      _getMapTypeLabel(_mapType),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: EthioColors.muted),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                _buildMapTypeMenuItem(MapType.normal, 'Normal Road Map', Icons.map_outlined),
                _buildMapTypeMenuItem(MapType.satellite, 'Satellite View', Icons.satellite_alt_rounded),
                _buildMapTypeMenuItem(MapType.terrain, 'Terrain & Elevation', Icons.terrain_rounded),
                _buildMapTypeMenuItem(MapType.hybrid, 'Hybrid (Sat + Roads)', Icons.layers_rounded),
              ],
            ),
          ),

          // 4. Map Control Buttons: Zoom In, Zoom Out, Recenter
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Re-center Route',
                  onTap: _recenterRoute,
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MapType> _buildMapTypeMenuItem(MapType type, String title, IconData icon) {
    final isSelected = _mapType == type;
    return PopupMenuItem<MapType>(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? EthioColors.forest : EthioColors.stone),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? EthioColors.forest : EthioColors.charcoal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: EthioColors.forest),
          ],
        ],
      ),
    );
  }

  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
      case MapType.normal:
        return Icons.map_outlined;
      case MapType.satellite:
        return Icons.satellite_alt_rounded;
      case MapType.terrain:
        return Icons.terrain_rounded;
      case MapType.hybrid:
        return Icons.layers_rounded;
      default:
        return Icons.map;
    }
  }

  String _getMapTypeLabel(MapType type) {
    switch (type) {
      case MapType.normal:
        return 'Normal';
      case MapType.satellite:
        return 'Satellite';
      case MapType.terrain:
        return 'Terrain';
      case MapType.hybrid:
        return 'Hybrid';
      default:
        return 'Normal';
    }
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: highlight ? EthioColors.forest : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? EthioColors.forestLight : EthioColors.divider,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: EthioColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: highlight ? Colors.white : EthioColors.charcoal,
          ),
        ),
      ),
    );
  }
}
