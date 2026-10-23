import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/landmark.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/navigation/route_map_viewer.dart';
import '../../widgets/navigation/ar_camera_background_view.dart';
import 'ar_attraction_experience_page.dart';

class ArRealtimeNavigationPage extends StatefulWidget {
  final String destinationName;
  final LatLng destinationLocation;
  final RouteResult initialRouteResult;
  final Landmark? destinationLandmark;
  final TravelMode travelMode;

  const ArRealtimeNavigationPage({
    super.key,
    required this.destinationName,
    required this.destinationLocation,
    required this.initialRouteResult,
    this.destinationLandmark,
    this.travelMode = TravelMode.walking,
  });

  @override
  State<ArRealtimeNavigationPage> createState() => _ArRealtimeNavigationPageState();
}

class _ArRealtimeNavigationPageState extends State<ArRealtimeNavigationPage>
    with SingleTickerProviderStateMixin {
  final RoutingService _routingService = RoutingService();

  late RouteResult _currentRoute;
  late LatLng _currentGpsPosition;
  double _currentHeadingDegrees = 0.0; // Compass heading
  double _currentSpeedKmh = 0.0;
  double _remainingDistanceMeters = 0.0;
  int _currentStepIndex = 0;

  // Real-time Dynamic Guidance States
  bool _isOffRoad = false;
  double _distanceToRoad = 0.0;
  bool _hasTriggeredTurnNow = false;
  int _lastTurnedJunctionIndex = -1;
  ManeuverType _dynamicManeuver = ManeuverType.continueStraight;
  String _dynamicInstruction = '';
  bool _isWrongDirection = false;
  bool _isMoveBackward = false;

  // Streams & Timers
  StreamSubscription<Position>? _positionStream;
  Timer? _simulatedGpsTimer;
  bool _isSimulatingGps = false;
  double _simProgress = 0.0;

  bool _isRecalculating = false;
  bool _hasArrived = false;
  final bool _showMiniMap = true;
  bool _isExpandedMap = false;

  late AnimationController _arPulseController;

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRouteResult;
    _currentGpsPosition = _currentRoute.startLocation;
    _remainingDistanceMeters = _currentRoute.totalDistanceMeters;

    _arPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startLiveGpsTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _simulatedGpsTimer?.cancel();
    _arPulseController.dispose();
    super.dispose();
  }

  Future<void> _startLiveGpsTracking() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
          _enableSimulatedGpsFallback();
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _onGpsUpdate(pos.latitude, pos.longitude, pos.heading, pos.speed);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
        ),
      ).listen((p) {
        _onGpsUpdate(p.latitude, p.longitude, p.heading, p.speed);
      });
    } catch (_) {
      // If native GPS fails (e.g. browser permissions or mock environment), enable graceful continuous simulator
      _enableSimulatedGpsFallback();
    }
  }

  void _enableSimulatedGpsFallback() {
    if (_isSimulatingGps) return;
    _isSimulatingGps = true;

    _simulatedGpsTimer?.cancel();
    _simulatedGpsTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      final points = _currentRoute.polylinePoints;
      if (points.isEmpty) return;

      final delta = (widget.travelMode == TravelMode.driving ? 0.0025 : 0.0012);
      _simProgress = (_simProgress + delta).clamp(0.0, 1.0);

      final exactIdx = _simProgress * (points.length - 1);
      final idx1 = exactIdx.floor().clamp(0, points.length - 1);
      final idx2 = (idx1 + 1).clamp(0, points.length - 1);
      final fraction = exactIdx - idx1;

      final p1 = points[idx1];
      final p2 = points[idx2];

      final lat = p1.latitude + (p2.latitude - p1.latitude) * fraction;
      final lon = p1.longitude + (p2.longitude - p1.longitude) * fraction;

      // Bearing
      final dy = p2.latitude - p1.latitude;
      final dx = (p2.longitude - p1.longitude) * math.cos(p1.latitude * math.pi / 180.0);
      final heading = (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;

      final speed = widget.travelMode == TravelMode.driving ? 32.0 : 4.5;
      _onGpsUpdate(lat, lon, heading, speed / 3.6);
    });
  }

  void _onGpsUpdate(double lat, double lon, double heading, double speedMs) {
    if (_hasArrived || !mounted) return;

    final newPos = LatLng(lat, lon);
    final distToDest = _distanceBetween(newPos, widget.destinationLocation);

    setState(() {
      _currentGpsPosition = newPos;
      if (heading > 0) _currentHeadingDegrees = heading;
      _currentSpeedKmh = speedMs * 3.6;
      _remainingDistanceMeters = distToDest;
      _updateCurrentStepIndex();
      _evaluateGuidanceState(newPos);
    });

    // 1. Arrival Check (< 25 meters, after navigation has actually progressed)
    if (distToDest <= 25 && !_hasArrived) {
      if (!_isSimulatingGps || _simProgress >= 0.90) {
        _hasArrived = true;
        _triggerArrival();
        return;
      }
    }

    // 2. Off-Route Detection (> 55 meters from nearest route polyline point)
    _checkRouteDeviation(newPos);
  }

  void _updateCurrentStepIndex() {
    final steps = _currentRoute.steps;
    if (steps.isEmpty) return;

    for (int i = _currentStepIndex; i < steps.length; i++) {
      final distToStep = _distanceBetween(_currentGpsPosition, steps[i].location);
      if (distToStep < 18 && i < steps.length - 1) {
        _currentStepIndex = i + 1;
        break;
      }
    }
  }

  void _evaluateGuidanceState(LatLng current) {
    final steps = _currentRoute.steps;
    if (steps.isEmpty) return;

    // Check distance to closest point on route polyline
    final points = _currentRoute.polylinePoints;
    double minRoadDist = double.infinity;
    for (final p in points) {
      final d = _distanceBetween(current, p);
      if (d < minRoadDist) minRoadDist = d;
    }

    // Off-Road guidance mode (between 15m and 55m away from road)
    if (minRoadDist > 15.0 && minRoadDist <= 55.0) {
      _isOffRoad = true;
      _distanceToRoad = minRoadDist;
      _dynamicManeuver = ManeuverType.offRoadConnect;
      _dynamicInstruction = 'Head towards road (${minRoadDist.round()}m)';
      return;
    }
    _isOffRoad = false;

    final stepIdx = _currentStepIndex.clamp(0, steps.length - 1);
    final currentStep = steps[stepIdx];
    final distToStep = _distanceBetween(current, currentStep.location);
    final targetBearing = _calculateBearing(current, currentStep.location);

    // Calculate heading difference
    double headingDelta = (_currentHeadingDegrees - targetBearing).abs() % 360;
    if (headingDelta > 180) headingDelta = 360 - headingDelta;

    // 1. Move Backward / Turn Around (Angle discrepancy >= 135°)
    if (headingDelta >= 135.0) {
      _isMoveBackward = true;
      _isWrongDirection = false;
      _dynamicManeuver = ManeuverType.uTurn;
      _dynamicInstruction = 'Move backward / Make a U-turn';
      return;
    }

    // 2. Wrong Direction Warning (Angle discrepancy >= 85°)
    if (headingDelta >= 85.0) {
      _isWrongDirection = true;
      _isMoveBackward = false;
      _dynamicManeuver = ManeuverType.wrongDirection;
      _dynamicInstruction = 'Wrong direction! Turn around';
      return;
    }

    _isMoveBackward = false;
    _isWrongDirection = false;

    final isTurn = currentStep.maneuverType == ManeuverType.turnRight ||
        currentStep.maneuverType == ManeuverType.turnLeft ||
        currentStep.maneuverType == ManeuverType.turnSharpRight ||
        currentStep.maneuverType == ManeuverType.turnSharpLeft;

    // 3. Exact Turn Prompt at the Junction (<= 12 meters)
    if (distToStep <= 12.0 && isTurn) {
      _hasTriggeredTurnNow = true;
      _lastTurnedJunctionIndex = stepIdx;
      final turnSide = (currentStep.maneuverType == ManeuverType.turnLeft || currentStep.maneuverType == ManeuverType.turnSharpLeft)
          ? 'left'
          : 'right';
      _dynamicManeuver = currentStep.maneuverType;
      _dynamicInstruction = 'Turn $turnSide now';
      return;
    }

    // 4. Transition to "Head out" when the turn has been made
    if (_hasTriggeredTurnNow && _lastTurnedJunctionIndex == stepIdx - 1 && headingDelta <= 30.0) {
      _dynamicManeuver = ManeuverType.headOut;
      _dynamicInstruction = 'Head out straight along path';
      return;
    }

    _dynamicManeuver = currentStep.maneuverType;
    _dynamicInstruction = currentStep.instruction;
  }

  double _calculateBearing(LatLng start, LatLng dest) {
    final startLat = start.latitude * (math.pi / 180.0);
    final startLng = start.longitude * (math.pi / 180.0);
    final endLat = dest.latitude * (math.pi / 180.0);
    final endLng = dest.longitude * (math.pi / 180.0);

    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    double bearing = math.atan2(y, x) * (180.0 / math.pi);
    return (bearing + 360.0) % 360.0;
  }

  void _checkRouteDeviation(LatLng current) {
    if (_isRecalculating) return;

    final points = _currentRoute.polylinePoints;
    if (points.isEmpty) return;

    double minDistance = double.infinity;
    for (final p in points) {
      final d = _distanceBetween(current, p);
      if (d < minDistance) minDistance = d;
    }

    if (minDistance > 55.0) {
      _recalculateRoute(current);
    }
  }

  Future<void> _recalculateRoute(LatLng current) async {
    setState(() => _isRecalculating = true);

    try {
      final newRoute = await _routingService.calculateRoute(
        start: current,
        destination: widget.destinationLocation,
        mode: widget.travelMode,
      );

      if (mounted) {
        setState(() {
          _currentRoute = newRoute;
          _isRecalculating = false;
          _currentStepIndex = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EthioColors.terracotta,
            duration: const Duration(seconds: 2),
            content: Row(
              children: const [
                Icon(Icons.alt_route_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Route recalculated based on your new location!'),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isRecalculating = false);
    }
  }

  void _triggerArrival() {
    _simulatedGpsTimer?.cancel();
    _positionStream?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Column(
          children: const [
            Icon(Icons.flag_rounded, color: EthioColors.forest, size: 48),
            SizedBox(height: 10),
            Text(
              "You've Arrived!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: EthioColors.charcoal),
            ),
          ],
        ),
        content: Text(
          'You have reached ${widget.destinationName}. Welcome to the attraction AR experience!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: EthioColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => ArAttractionExperiencePage(
                    attractionName: widget.destinationName,
                    landmark: widget.destinationLandmark,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.view_in_ar_rounded),
            label: const Text('Start AR Experience', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  double _distanceBetween(LatLng p1, LatLng p2) {
    return LocationService.calculateDistanceKm(
          p1.latitude,
          p1.longitude,
          p2.latitude,
          p2.longitude,
        ) *
        1000.0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = (_currentRoute.steps.isNotEmpty && _currentStepIndex < _currentRoute.steps.length)
        ? _currentRoute.steps[_currentStepIndex]
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Stream Background
          Positioned.fill(
            child: const ArCameraBackgroundView(),
          ),

          // 2. Immersive AR Directional 3D Perspective Ground Path & Floating Arrows
          Positioned.fill(
            child: _buildArDirectionalOverlay(currentStep),
          ),

          // 3. Top Floating Real-Time AR Navigation HUD Banner
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _buildArNavigationHud(currentStep),
          ),

          // 4. Recalculating Route Overlay Banner (if triggered)
          if (_isRecalculating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 160,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: EthioColors.terracotta,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Off-route detected: Recalculating...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Mini-Map / Split Navigation View (Expandable)
          if (_showMiniMap)
            Positioned(
              bottom: 24,
              right: 16,
              child: _buildMiniMap(),
            ),

          // 6. Bottom Navigation Controls & Simulation Toggles
          Positioned(
            bottom: 24,
            left: 16,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  // Top Floating AR HUD Banner
  Widget _buildArNavigationHud(RouteStep? currentStep) {
    final distRemainingStr = _remainingDistanceMeters < 1000
        ? '${_remainingDistanceMeters.round()} m'
        : '${(_remainingDistanceMeters / 1000).toStringAsFixed(1)} km';

    final etaMins = math.max(1, (_remainingDistanceMeters / (widget.travelMode == TravelMode.driving ? 9.7 : 1.3) / 60).round());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: EthioColors.forest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'LIVE GPS AR NAV',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ETA: $etaMins min',
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Maneuver Icon & Instruction
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (_isWrongDirection || _isMoveBackward)
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : (_isOffRoad
                          ? Colors.cyanAccent.withValues(alpha: 0.3)
                          : EthioColors.forestLight.withValues(alpha: 0.3)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_isWrongDirection || _isMoveBackward)
                        ? Colors.redAccent
                        : (_isOffRoad ? Colors.cyanAccent : Colors.greenAccent),
                  ),
                ),
                child: Icon(
                  _getManeuverIconData(_dynamicManeuver),
                  color: (_isWrongDirection || _isMoveBackward)
                      ? Colors.redAccent
                      : (_isOffRoad ? Colors.cyanAccent : Colors.greenAccent),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dynamicInstruction.isNotEmpty
                          ? _dynamicInstruction
                          : (currentStep?.instruction ?? 'Proceed to ${widget.destinationName}'),
                      style: TextStyle(
                        color: (_isWrongDirection || _isMoveBackward) ? Colors.redAccent : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isOffRoad
                          ? '📍 Heading towards walkway access (${_distanceToRoad.round()}m) • ${_currentSpeedKmh.toStringAsFixed(1)} km/h'
                          : '📍 $distRemainingStr remaining • ${_currentSpeedKmh.toStringAsFixed(1)} km/h',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getManeuverIconData(ManeuverType? type) {
    switch (type) {
      case ManeuverType.turnRight:
      case ManeuverType.turnSharpRight:
      case ManeuverType.turnSlightRight:
        return Icons.turn_right_rounded;
      case ManeuverType.turnLeft:
      case ManeuverType.turnSharpLeft:
      case ManeuverType.turnSlightLeft:
        return Icons.turn_left_rounded;
      case ManeuverType.roundabout:
        return Icons.rotate_right_rounded;
      case ManeuverType.uTurn:
        return Icons.u_turn_left_rounded;
      case ManeuverType.headOut:
        return Icons.arrow_upward_rounded;
      case ManeuverType.wrongDirection:
        return Icons.warning_amber_rounded;
      case ManeuverType.offRoadConnect:
        return Icons.alt_route_rounded;
      case ManeuverType.arrive:
        return Icons.flag_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  // 3D Perspective Ground Path & Directional Arrow Overlay
  Widget _buildArDirectionalOverlay(RouteStep? step) {
    return AnimatedBuilder(
      animation: _arPulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ArPerspectiveOverlayPainter(
            heading: _currentHeadingDegrees,
            pulse: _arPulseController.value,
            travelMode: widget.travelMode,
            nextInstruction: _dynamicInstruction.isNotEmpty ? _dynamicInstruction : (step?.instruction ?? 'Walk Straight'),
            maneuverType: _dynamicManeuver,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  // Expandable Mini-Map
  Widget _buildMiniMap() {
    final mapWidth = _isExpandedMap ? 280.0 : 130.0;
    final mapHeight = _isExpandedMap ? 280.0 : 130.0;

    return GestureDetector(
      onTap: () => setState(() => _isExpandedMap = !_isExpandedMap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: mapWidth,
        height: mapHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              RouteMapViewer(
                polylinePoints: _currentRoute.polylinePoints,
                startLocation: _currentGpsPosition,
                endLocation: widget.destinationLocation,
                animatedMarkerPosition: _currentGpsPosition,
                animatedMarkerHeading: _currentHeadingDegrees * math.pi / 180.0,
                travelMode: widget.travelMode,
                startLabel: 'You',
                destinationLabel: widget.destinationName,
                isPreviewMode: false,
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isExpandedMap ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode indicator pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
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
                widget.travelMode == TravelMode.driving ? 'DRIVING AR HUD' : 'WALKING AR HUD',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Quick Attraction Arrival Trigger Button (Allows manual entry for demo)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: EthioColors.forest,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _triggerArrival,
          icon: const Icon(Icons.castle_rounded, size: 18),
          label: const Text('Arrive at Attraction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _ArPerspectiveOverlayPainter extends CustomPainter {
  final double heading;
  final double pulse;
  final TravelMode travelMode;
  final String nextInstruction;
  final ManeuverType maneuverType;

  _ArPerspectiveOverlayPainter({
    required this.heading,
    required this.pulse,
    required this.travelMode,
    required this.nextInstruction,
    required this.maneuverType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final horizonY = size.height * 0.45;
    final groundY = size.height * 0.85;

    // 1. Draw 3D Perspective Ground Beacons / Light Path
    final path = Path();
    path.moveTo(centerX - 80, groundY);
    path.lineTo(centerX + 80, groundY);
    path.lineTo(centerX + 18, horizonY);
    path.lineTo(centerX - 18, horizonY);
    path.close();

    final pathGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        (travelMode == TravelMode.driving ? Colors.greenAccent : Colors.amberAccent).withValues(alpha: 0.35 + pulse * 0.15),
        Colors.transparent,
      ],
    );

    final pathPaint = Paint()
      ..shader = pathGradient.createShader(Rect.fromLTWH(0, horizonY, size.width, groundY - horizonY));
    canvas.drawPath(path, pathPaint);

    // 2. Draw Floating 3D Turn Chevrons Along the Path
    for (int i = 0; i < 4; i++) {
      final t = (i / 4.0 + pulse * 0.25) % 1.0;
      final curY = groundY - t * (groundY - horizonY);
      final scale = 1.0 - t * 0.7;
      final curW = 40.0 * scale;

      final chevronPath = Path();
      chevronPath.moveTo(centerX - curW, curY + 10 * scale);
      chevronPath.lineTo(centerX, curY - 10 * scale);
      chevronPath.lineTo(centerX + curW, curY + 10 * scale);

      final chevronPaint = Paint()
        ..color = Colors.white.withValues(alpha: 1.0 - t * 0.6)
        ..strokeWidth = 5.0 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(chevronPath, chevronPaint);
    }

    // 3. Draw Center AR Floating Turn Navigation Marker (e.g. Turn Right ➜, Head Out ⇈, U-Turn ↷)
    final markerCenter = Offset(centerX, size.height * 0.42);

    Color markerAccentColor = Colors.greenAccent;
    String arrowChar = '↑';

    if (maneuverType == ManeuverType.turnRight || maneuverType == ManeuverType.turnSharpRight || maneuverType == ManeuverType.turnSlightRight) {
      arrowChar = '➜';
      markerAccentColor = Colors.amberAccent;
    } else if (maneuverType == ManeuverType.turnLeft || maneuverType == ManeuverType.turnSharpLeft || maneuverType == ManeuverType.turnSlightLeft) {
      arrowChar = '⬅';
      markerAccentColor = Colors.amberAccent;
    } else if (maneuverType == ManeuverType.uTurn) {
      arrowChar = '↷';
      markerAccentColor = Colors.redAccent;
    } else if (maneuverType == ManeuverType.wrongDirection) {
      arrowChar = '⚠️';
      markerAccentColor = Colors.redAccent;
    } else if (maneuverType == ManeuverType.headOut) {
      arrowChar = '⇈';
      markerAccentColor = Colors.greenAccent;
    } else if (maneuverType == ManeuverType.offRoadConnect) {
      arrowChar = '↗';
      markerAccentColor = Colors.cyanAccent;
    }

    final ringPaint = Paint()
      ..color = markerAccentColor.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(markerCenter, 32 + pulse * 4, ringPaint);

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.80);
    canvas.drawCircle(markerCenter, 28, bgPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: arrowChar,
        style: TextStyle(
          color: markerAccentColor,
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(markerCenter.dx - textPainter.width / 2, markerCenter.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ArPerspectiveOverlayPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.heading != heading ||
        oldDelegate.maneuverType != maneuverType;
  }
}
