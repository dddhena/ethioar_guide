import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../../config/api_config.dart';
import '../../services/routing_service.dart';
import '../../theme/ethio_theme.dart';

enum OsmMapStyle {
  custom,
  voyager,
  standard,
  topographic,
}

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
  final MapController _mapController = MapController();
  late OsmMapStyle _mapStyle;

  @override
  void initState() {
    super.initState();
    _mapStyle = (ApiConfig.osmApiKey.isNotEmpty) ? OsmMapStyle.custom : OsmMapStyle.voyager;
  }

  osm.LatLng _toOsm(LatLng p) => osm.LatLng(p.latitude, p.longitude);

  @override
  void didUpdateWidget(covariant RouteMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Follow animated marker if active
    if (widget.animatedMarkerPosition != null &&
        widget.animatedMarkerPosition != oldWidget.animatedMarkerPosition) {
      _mapController.move(
        _toOsm(widget.animatedMarkerPosition!),
        _mapController.camera.zoom,
      );
    } else if (widget.polylinePoints != oldWidget.polylinePoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
    }
  }

  void _fitBounds() {
    final points = widget.polylinePoints.isNotEmpty
        ? widget.polylinePoints
        : [widget.startLocation, widget.endLocation];

    if (points.isEmpty) return;

    final osmPoints = points.map(_toOsm).toList();
    if (widget.waypoints != null && widget.waypoints!.isNotEmpty) {
      osmPoints.addAll(widget.waypoints!.map(_toOsm));
    }

    try {
      final bounds = LatLngBounds.fromPoints(osmPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(55.0),
        ),
      );
    } catch (_) {}
  }

  void _recenterRoute() {
    widget.onRecenter?.call();
    _fitBounds();
  }

  String _getTileUrl(OsmMapStyle style) {
    switch (style) {
      case OsmMapStyle.custom:
        return ApiConfig.resolvedTileUrl;
      case OsmMapStyle.voyager:
        return 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
      case OsmMapStyle.topographic:
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case OsmMapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    final startTitle = widget.startLabel.isNotEmpty ? widget.startLabel : 'Starting Point';
    final destTitle = widget.destinationLabel.isNotEmpty ? widget.destinationLabel : 'Destination';

    // 1. Start Marker (Blue / Azure)
    markers.add(
      Marker(
        point: _toOsm(widget.startLocation),
        width: 48,
        height: 48,
        child: Tooltip(
          message: '$startTitle (Departure)',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.trip_origin_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );

    // 2. Destination Marker (Red / Rose)
    markers.add(
      Marker(
        point: _toOsm(widget.endLocation),
        width: 48,
        height: 48,
        child: Tooltip(
          message: '$destTitle (Arrival)',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );

    // 3. Intermediate Waypoints (Orange)
    if (widget.waypoints != null) {
      for (int i = 0; i < widget.waypoints!.length; i++) {
        final label = (widget.waypointLabels != null && i < widget.waypointLabels!.length)
            ? widget.waypointLabels![i]
            : 'Tour Stop ${i + 1}';

        markers.add(
          Marker(
            point: _toOsm(widget.waypoints![i]),
            width: 40,
            height: 40,
            child: Tooltip(
              message: label,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // 4. Moving Animated Marker (Traveler / Vehicle)
    if (widget.animatedMarkerPosition != null) {
      markers.add(
        Marker(
          point: _toOsm(widget.animatedMarkerPosition!),
          width: 50,
          height: 50,
          child: Transform.rotate(
            angle: widget.animatedMarkerHeading,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: widget.travelMode == TravelMode.driving
                    ? Colors.amber.shade700
                    : Colors.green.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                widget.travelMode == TravelMode.driving
                    ? Icons.directions_car_rounded
                    : Icons.directions_walk_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final points = widget.polylinePoints.isNotEmpty
        ? widget.polylinePoints
        : [widget.startLocation, widget.endLocation];

    return [
      Polyline(
        points: points.map(_toOsm).toList(),
        strokeWidth: 5.5,
        color: widget.travelMode == TravelMode.driving
            ? const Color(0xFF1E6B3B)
            : const Color(0xFFC4784A),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final midLat = (widget.startLocation.latitude + widget.endLocation.latitude) / 2;
    final midLon = (widget.startLocation.longitude + widget.endLocation.longitude) / 2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // 1. Free OpenStreetMap via FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: osm.LatLng(midLat, midLon),
              initialZoom: 14.0,
              onMapReady: () {
                WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(_mapStyle),
                userAgentPackageName: ApiConfig.osmUserAgent,
                maxZoom: 19,
              ),
              PolylineLayer(
                polylines: _buildPolylines(),
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
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

          // 3. Map Style Selector Menu (Top Right)
          Positioned(
            top: 16,
            right: 16,
            child: PopupMenuButton<OsmMapStyle>(
              initialValue: _mapStyle,
              tooltip: 'Change Map Style',
              onSelected: (style) => setState(() => _mapStyle = style),
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
                    Icon(_getMapStyleIcon(_mapStyle), size: 16, color: EthioColors.forest),
                    const SizedBox(width: 6),
                    Text(
                      _getMapStyleLabel(_mapStyle),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: EthioColors.muted),
                  ],
                ),
              ),
              itemBuilder: (ctx) => [
                _buildMapStyleMenuItem(OsmMapStyle.voyager, 'Voyager (Clean Roads)', Icons.map_outlined),
                _buildMapStyleMenuItem(OsmMapStyle.standard, 'Standard OpenStreetMap', Icons.public_rounded),
                _buildMapStyleMenuItem(OsmMapStyle.topographic, 'Topographic & Hills', Icons.terrain_rounded),
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
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
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

  PopupMenuItem<OsmMapStyle> _buildMapStyleMenuItem(OsmMapStyle style, String title, IconData icon) {
    final isSelected = _mapStyle == style;
    return PopupMenuItem<OsmMapStyle>(
      value: style,
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

  IconData _getMapStyleIcon(OsmMapStyle style) {
    switch (style) {
      case OsmMapStyle.custom:
        return Icons.tune_rounded;
      case OsmMapStyle.voyager:
        return Icons.map_outlined;
      case OsmMapStyle.standard:
        return Icons.public_rounded;
      case OsmMapStyle.topographic:
        return Icons.terrain_rounded;
    }
  }

  String _getMapStyleLabel(OsmMapStyle style) {
    switch (style) {
      case OsmMapStyle.custom:
        return 'Custom / API';
      case OsmMapStyle.voyager:
        return 'Voyager';
      case OsmMapStyle.standard:
        return 'Standard';
      case OsmMapStyle.topographic:
        return 'Topographic';
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
            boxShadow: [
              BoxShadow(
                color: EthioColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
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
