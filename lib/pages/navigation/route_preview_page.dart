import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/landmark.dart';
import '../../models/tour_package.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/navigation/route_map_viewer.dart';
import 'ar_realtime_navigation_page.dart';

enum JourneyContext {
  arDiscovery,
  guidedJourney,
}

class RoutePreviewPage extends StatefulWidget {
  final Landmark? destinationLandmark;
  final TourPackage? guidedTour;
  final LatLng? customStartLocation;
  final LatLng? customDestination;
  final String destinationTitle;
  final JourneyContext contextMode;

  const RoutePreviewPage({
    super.key,
    this.destinationLandmark,
    this.guidedTour,
    this.customStartLocation,
    this.customDestination,
    this.destinationTitle = 'Fasil Ghebbi',
    this.contextMode = JourneyContext.arDiscovery,
  });

  @override
  State<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends State<RoutePreviewPage> with SingleTickerProviderStateMixin {
  final RoutingService _routingService = RoutingService();
  
  TravelMode _travelMode = TravelMode.driving;
  bool _isLoadingRoute = true;
  bool _isLocatingUser = false;
  bool _isUsingCurrentLocation = false;
  String _startLocationName = 'Starting Point';
  RouteResult? _routeResult;

  // Animation preview state
  bool _isPlayingPreview = false;
  double _animationProgress = 0.0; // 0.0 to 1.0
  double _playbackSpeed = 1.0; // 0.5x, 1.0x, 2.0x
  Timer? _animationTimer;

  LatLng? _currentAnimatedPos;
  double _currentAnimatedHeading = 0.0;

  // Start and End points
  late LatLng _startLocation;
  late LatLng _destinationLocation;
  List<LatLng> _guidedWaypoints = [];
  List<String> _guidedWaypointNames = [];

  @override
  void initState() {
    super.initState();
    _initializeLocationsAndRoute();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocationsAndRoute() async {
    // 1. Destination Setup
    if (widget.destinationLandmark != null) {
      _destinationLocation = LatLng(
        widget.destinationLandmark!.latitude,
        widget.destinationLandmark!.longitude,
      );
    } else if (widget.customDestination != null) {
      _destinationLocation = widget.customDestination!;
    } else {
      // Default to Fasil Ghebbi, Gondar (12.6074, 37.4697)
      _destinationLocation = const LatLng(12.6074, 37.4697);
    }

    // 2. Starting Point Setup:
    // If a custom start location is provided, use that.
    // Otherwise, automatically acquire the user's live current location!
    if (widget.customStartLocation != null) {
      _startLocation = widget.customStartLocation!;
      _startLocationName = 'Custom Starting Location';
      _isUsingCurrentLocation = false;
      _isLocatingUser = false;
      if (widget.contextMode == JourneyContext.guidedJourney && widget.guidedTour != null) {
        _setupGuidedTourWaypoints();
      }
      await _loadRoute();
    } else {
      // Fallback position near destination while GPS resolves
      _startLocation = LatLng(
        _destinationLocation.latitude - 0.0154,
        _destinationLocation.longitude - 0.0142,
      );
      _startLocationName = 'Detecting current GPS location...';
      _isLocatingUser = true;

      setState(() {
        _isLoadingRoute = true;
      });

      try {
        final currentPos = await LocationService.getCurrentUserLocation();
        if (mounted) {
          if (currentPos != null) {
            _startLocation = currentPos;
            _startLocationName = 'My Current Location';
            _isUsingCurrentLocation = true;
          } else {
            _startLocationName = 'Nearby Departure Point';
            _isUsingCurrentLocation = false;
          }
        }
      } catch (_) {
        if (mounted) {
          _startLocationName = 'Nearby Departure Point';
          _isUsingCurrentLocation = false;
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLocatingUser = false;
          });
        }
      }

      if (widget.contextMode == JourneyContext.guidedJourney && widget.guidedTour != null) {
        _setupGuidedTourWaypoints();
      }

      await _loadRoute();
    }
  }

  Future<void> _refreshCurrentLocation() async {
    setState(() {
      _isLocatingUser = true;
      _isLoadingRoute = true;
      _stopAnimation();
    });

    final currentPos = await LocationService.getCurrentUserLocation();
    if (!mounted) return;

    if (currentPos != null) {
      setState(() {
        _startLocation = currentPos;
        _startLocationName = 'My Current Location';
        _isUsingCurrentLocation = true;
        _isLocatingUser = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Starting point updated to your current GPS location!'),
            ],
          ),
          backgroundColor: EthioColors.forest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _isLocatingUser = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Could not detect GPS location. Please check permissions.')),
            ],
          ),
          backgroundColor: EthioColors.terracotta,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (widget.contextMode == JourneyContext.guidedJourney && widget.guidedTour != null) {
      _setupGuidedTourWaypoints();
    }

    await _loadRoute();
  }

  void _setupGuidedTourWaypoints() {
    final dLat = _destinationLocation.latitude - _startLocation.latitude;
    final dLon = _destinationLocation.longitude - _startLocation.longitude;

    _guidedWaypoints = [
      LatLng(_startLocation.latitude + dLat * 0.25, _startLocation.longitude + dLon * 0.25),
      LatLng(_startLocation.latitude + dLat * 0.60, _startLocation.longitude + dLon * 0.60),
      LatLng(_startLocation.latitude + dLat * 0.85, _startLocation.longitude + dLon * 0.85),
    ];
    _guidedWaypointNames = [
      'Guide Meeting Point (${widget.guidedTour?.name ?? "Gondar Plaza"})',
      'Historical Stop & Pavilion',
      'Scenic Royal Enclosure Entrance',
    ];
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoadingRoute = true;
      _stopAnimation();
    });

    try {
      final route = await _routingService.calculateRoute(
        start: _startLocation,
        destination: _destinationLocation,
        mode: _travelMode,
        intermediateWaypoints: _guidedWaypoints.isNotEmpty ? _guidedWaypoints : null,
      );

      if (mounted) {
        setState(() {
          _routeResult = route;
          _isLoadingRoute = false;
          _currentAnimatedPos = route.polylinePoints.isNotEmpty ? route.polylinePoints.first : _startLocation;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _onModeChanged(TravelMode mode) {
    if (_travelMode == mode) return;
    setState(() => _travelMode = mode);
    _loadRoute();
  }

  // Animation Preview Logic
  void _startOrResumeAnimation() {
    if (_routeResult == null || _routeResult!.polylinePoints.isEmpty) return;

    if (_animationProgress >= 1.0) {
      _animationProgress = 0.0;
    }

    setState(() => _isPlayingPreview = true);

    _animationTimer?.cancel();
    const intervalMs = 30; // Smooth ~33fps
    _animationTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final baseStep = 0.003;
      final step = baseStep * _playbackSpeed;

      setState(() {
        _animationProgress += step;

        if (_animationProgress >= 1.0) {
          _animationProgress = 1.0;
          _isPlayingPreview = false;
          timer.cancel();
          _updateAnimatedPositionAndHeading(1.0);
          _showArrivalSnackbar();
        } else {
          _updateAnimatedPositionAndHeading(_animationProgress);
        }
      });
    });
  }

  void _pauseAnimation() {
    _animationTimer?.cancel();
    setState(() => _isPlayingPreview = false);
  }

  void _restartAnimation() {
    _animationTimer?.cancel();
    setState(() {
      _animationProgress = 0.0;
      _isPlayingPreview = false;
      _updateAnimatedPositionAndHeading(0.0);
    });
    _startOrResumeAnimation();
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _isPlayingPreview = false;
    _animationProgress = 0.0;
  }

  void _setSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_isPlayingPreview) {
      _startOrResumeAnimation();
    }
  }

  void _updateAnimatedPositionAndHeading(double progress) {
    final points = _routeResult?.polylinePoints ?? [];
    if (points.length < 2) return;

    final exactIdx = progress * (points.length - 1);
    final idx1 = exactIdx.floor().clamp(0, points.length - 1);
    final idx2 = (idx1 + 1).clamp(0, points.length - 1);
    final fraction = exactIdx - idx1;

    final p1 = points[idx1];
    final p2 = points[idx2];

    final lat = p1.latitude + (p2.latitude - p1.latitude) * fraction;
    final lon = p1.longitude + (p2.longitude - p1.longitude) * fraction;
    _currentAnimatedPos = LatLng(lat, lon);

    final dy = p2.latitude - p1.latitude;
    final dx = (p2.longitude - p1.longitude) * math.cos(p1.latitude * math.pi / 180.0);
    _currentAnimatedHeading = math.atan2(dx, dy);
  }

  void _showArrivalSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EthioColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Route preview completed for ${_getDestinationName()}!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDestinationName() {
    if (widget.destinationLandmark != null) return widget.destinationLandmark!.name;
    if (widget.guidedTour != null) return widget.guidedTour!.name;
    return widget.destinationTitle;
  }

  void _startArJourney() {
    if (_routeResult == null) return;
    _stopAnimation();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArRealtimeNavigationPage(
          destinationName: _getDestinationName(),
          destinationLocation: _destinationLocation,
          initialRouteResult: _routeResult!,
          destinationLandmark: widget.destinationLandmark,
          travelMode: _travelMode,
        ),
      ),
    );
  }

  void _startGuidedTourBooking() {
    _stopAnimation();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.person_pin_circle_rounded, color: EthioColors.forest, size: 28),
            SizedBox(width: 10),
            Text('Guided Tour Itinerary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview completed for ${_getDestinationName()}.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EthioColors.sand.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('📍 Meeting Point: Gondar Plaza Gate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('👥 Certified Local Guide assigned', style: TextStyle(fontSize: 12, color: EthioColors.charcoal)),
                  SizedBox(height: 4),
                  Text('🧭 Standard Map Navigation (No AR camera needed)', style: TextStyle(fontSize: 12, color: EthioColors.muted)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EthioColors.forest,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Meeting details confirmed with your guide!'),
                  backgroundColor: EthioColors.forest,
                ),
              );
            },
            child: const Text('Confirm Guide Meeting'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: const Text('Preview Your Journey'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Route',
            onPressed: _loadRoute,
          ),
        ],
      ),
      body: isDesktop ? _buildSplitDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildSplitDesktopLayout() {
    return Row(
      children: [
        // Left Sidebar: Route Information, Controls & Maneuvers
        SizedBox(
          width: 440,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: _buildRouteControlDetails(isDesktop: true),
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: EthioColors.divider),
        // Right Side: Interactive Map with Style Options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildMapSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top Header Summary
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildHeaderSummary(),
        ),
        // Full Interactive Map
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _buildMapSection(),
          ),
        ),
        // Bottom Controls Sheet
        Expanded(
          flex: 4,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: EthioColors.cardShadow,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _buildRouteControlDetails(isDesktop: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSummary() {
    final destName = _getDestinationName();
    final summaryText = _routeResult != null
        ? _routeResult!.formattedSummary
        : (_isLoadingRoute ? 'Calculating precise route...' : '2.4 km • approximately 8 min');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.contextMode == JourneyContext.arDiscovery
                    ? EthioColors.forest.withOpacity(0.12)
                    : EthioColors.terracotta.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.contextMode == JourneyContext.arDiscovery
                        ? Icons.view_in_ar_rounded
                        : Icons.groups_rounded,
                    size: 14,
                    color: widget.contextMode == JourneyContext.arDiscovery
                        ? EthioColors.forest
                        : EthioColors.terracotta,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.contextMode == JourneyContext.arDiscovery
                        ? 'AR DISCOVERY'
                        : 'GUIDED JOURNEY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.contextMode == JourneyContext.arDiscovery
                          ? EthioColors.forest
                          : EthioColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Icon(Icons.verified_rounded, size: 16, color: EthioColors.forest),
            const SizedBox(width: 4),
            const Text(
              'OpenStreetMap Road Network',
              style: TextStyle(fontSize: 11, color: EthioColors.muted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          destName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: EthioColors.charcoal,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.route_rounded, size: 16, color: EthioColors.forest),
            const SizedBox(width: 6),
            Text(
              summaryText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: EthioColors.charcoal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    if (_isLoadingRoute) {
      return Container(
        decoration: BoxDecoration(
          color: EthioColors.sand,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: EthioColors.forest),
              SizedBox(height: 16),
              Text(
                'Calculating Road Geometry & Distance...',
                style: TextStyle(fontWeight: FontWeight.w600, color: EthioColors.earth),
              ),
            ],
          ),
        ),
      );
    }

    final points = _routeResult?.polylinePoints ?? [_startLocation, _destinationLocation];

    return RouteMapViewer(
      polylinePoints: points,
      startLocation: _startLocation,
      endLocation: _destinationLocation,
      waypoints: _guidedWaypoints,
      waypointLabels: _guidedWaypointNames,
      animatedMarkerPosition: _currentAnimatedPos,
      animatedMarkerHeading: _currentAnimatedHeading,
      travelMode: _travelMode,
      startLabel: _startLocationName,
      destinationLabel: _getDestinationName(),
      isPreviewMode: true,
      onRecenter: () {},
    );
  }

  Widget _buildOriginDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isUsingCurrentLocation ? EthioColors.forest.withOpacity(0.15) : EthioColors.sand,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isUsingCurrentLocation ? Icons.my_location_rounded : Icons.place_outlined,
                  size: 16,
                  color: _isUsingCurrentLocation ? EthioColors.forest : EthioColors.charcoal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'STARTING POINT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: EthioColors.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (_isLocatingUser) ...[
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: EthioColors.forest),
                          ),
                        ] else if (_isUsingCurrentLocation) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: EthioColors.forest.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Live GPS',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: EthioColors.forest),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _startLocationName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: EthioColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _isLocatingUser
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: EthioColors.forest),
                      )
                    : const Icon(Icons.gps_fixed_rounded, size: 20, color: EthioColors.forest),
                tooltip: 'Re-detect Current Location',
                onPressed: _isLocatingUser ? null : _refreshCurrentLocation,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
            child: Container(
              width: 2,
              height: 14,
              color: EthioColors.divider,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DESTINATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: EthioColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getDestinationName(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: EthioColors.charcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildRouteControlDetails({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop) ...[
          _buildHeaderSummary(),
          const Divider(height: 32, color: EthioColors.divider),
        ],

        // 1. Origin & Destination Summary Card
        _buildOriginDestinationCard(),

        const SizedBox(height: 16),

        // 2. Transportation Mode Selector
        const Text(
          'TRANSPORTATION MODE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: EthioColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        _buildTransportationSelector(),

        const SizedBox(height: 18),

        // 3. Route Animation Controls
        _buildAnimationControlsCard(),

        const SizedBox(height: 18),

        // 4. Guided Tour Waypoint Sequence (if Guided Mode)
        if (widget.contextMode == JourneyContext.guidedJourney) ...[
          _buildGuidedTourSequenceCard(),
          const SizedBox(height: 18),
        ],

        // 5. Turn-by-Turn Maneuvers Preview Accordion
        if (_routeResult != null && _routeResult!.steps.isNotEmpty) ...[
          _buildTurnByTurnPreview(),
          const SizedBox(height: 18),
        ],

        // 6. Primary Action Button
        _buildPrimaryActionButton(),
      ],
    );
  }

  Widget _buildTransportationSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EthioColors.sand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              mode: TravelMode.driving,
              icon: Icons.directions_car_rounded,
              label: '🚗 Drive',
              isSelected: _travelMode == TravelMode.driving,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildModeTab(
              mode: TravelMode.walking,
              icon: Icons.directions_walk_rounded,
              label: '🚶 Walk',
              isSelected: _travelMode == TravelMode.walking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required TravelMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _onModeChanged(mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? EthioColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EthioColors.forest.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : EthioColors.charcoal,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : EthioColors.charcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: EthioColors.forestLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_display_rounded, color: EthioColors.forest, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE PREVIEW ANIMATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: EthioColors.forest,
                      ),
                    ),
                    Text(
                      'Watch how the journey will look before you start.',
                      style: TextStyle(fontSize: 11, color: EthioColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _animationProgress,
              minHeight: 6,
              backgroundColor: EthioColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(EthioColors.forest),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EthioColors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isPlayingPreview ? _pauseAnimation : _startOrResumeAnimation,
                icon: Icon(
                  _isPlayingPreview ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  _isPlayingPreview ? 'Pause' : (_animationProgress > 0 ? 'Resume' : 'Preview'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: EthioColors.charcoal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: EthioColors.divider),
                ),
                onPressed: _restartAnimation,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 18),
                    SizedBox(width: 4),
                    Text('Restart', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              _buildSpeedChip(0.5),
              const SizedBox(width: 4),
              _buildSpeedChip(1.0),
              const SizedBox(width: 4),
              _buildSpeedChip(2.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChip(double speed) {
    final isSelected = _playbackSpeed == speed;
    return InkWell(
      onTap: () => _setSpeed(speed),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? EthioColors.charcoal : EthioColors.sand,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${speed}×',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : EthioColors.charcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildGuidedTourSequenceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: EthioColors.terracotta, size: 18),
              SizedBox(width: 6),
              Text(
                'GUIDED TOUR ITINERARY STOPS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: EthioColors.terracotta,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSequenceRow(icon: Icons.person_pin_circle_rounded, text: 'Tourist Starting Point', isFirst: true),
          _buildSequenceRow(icon: Icons.meeting_room_rounded, text: 'Guide Meeting Point (Gondar Plaza)'),
          _buildSequenceRow(icon: Icons.account_balance_rounded, text: 'Fasil Bath & Historical Pavilion'),
          _buildSequenceRow(icon: Icons.castle_rounded, text: 'Final Destination: Fasil Ghebbi Castles', isLast: true),
        ],
      ),
    );
  }

  Widget _buildSequenceRow({
    required IconData icon,
    required String text,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isLast ? EthioColors.forest : EthioColors.stone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                color: isLast ? EthioColors.forest : EthioColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnByTurnPreview() {
    final steps = _routeResult?.steps ?? [];
    return ExpansionTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: EthioColors.divider),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: const Icon(Icons.turn_right_rounded, color: EthioColors.forest),
      title: Text(
        'Turn-by-Turn Steps (${steps.length})',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: const Text(
        'Road maneuvers & navigation guidance',
        style: TextStyle(fontSize: 11, color: EthioColors.muted),
      ),
      children: steps.map((step) {
        return ListTile(
          dense: true,
          leading: _getManeuverIcon(step.maneuverType),
          title: Text(step.instruction, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: Text(step.formattedDistance, style: const TextStyle(fontSize: 12, color: EthioColors.muted)),
        );
      }).toList(),
    );
  }

  Widget _getManeuverIcon(ManeuverType type) {
    switch (type) {
      case ManeuverType.depart:
        return const Icon(Icons.navigation_rounded, size: 18, color: EthioColors.forest);
      case ManeuverType.turnRight:
      case ManeuverType.turnSharpRight:
      case ManeuverType.turnSlightRight:
        return const Icon(Icons.turn_right_rounded, size: 18, color: EthioColors.terracotta);
      case ManeuverType.turnLeft:
      case ManeuverType.turnSharpLeft:
      case ManeuverType.turnSlightLeft:
        return const Icon(Icons.turn_left_rounded, size: 18, color: EthioColors.terracotta);
      case ManeuverType.roundabout:
        return const Icon(Icons.rotate_right_rounded, size: 18, color: EthioColors.slate);
      case ManeuverType.arrive:
        return const Icon(Icons.flag_rounded, size: 18, color: Colors.red);
      default:
        return const Icon(Icons.straight_rounded, size: 18, color: EthioColors.forest);
    }
  }

  Widget _buildPrimaryActionButton() {
    if (widget.contextMode == JourneyContext.arDiscovery) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: EthioColors.forest,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        onPressed: _startArJourney,
        icon: const Icon(Icons.view_in_ar_rounded, size: 22),
        label: const Text(
          'Start AR Journey',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      );
    } else {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: EthioColors.earth,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
        ),
        onPressed: _startGuidedTourBooking,
        icon: const Icon(Icons.groups_rounded, size: 22),
        label: const Text(
          'Book / Begin Guided Tour',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      );
    }
  }
}
