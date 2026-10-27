import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/heritage_3d_landmark.dart';
import '../../models/landmark.dart';
import '../../theme/ethio_theme.dart';
import '../ar_guide.dart';
import 'cultural_ar_camera_page.dart';

class Heritage3DExplorerPage extends StatefulWidget {
  final Heritage3DLandmark? initialLandmark;

  const Heritage3DExplorerPage({super.key, this.initialLandmark});

  @override
  State<Heritage3DExplorerPage> createState() => _Heritage3DExplorerPageState();
}

class _Heritage3DExplorerPageState extends State<Heritage3DExplorerPage>
    with SingleTickerProviderStateMixin {
  late Heritage3DLandmark _currentLandmark;
  late AnimationController _animController;

  // 3D Rotation & Zoom angles
  double _rotationX = 0.35;
  double _rotationY = -0.55;
  double _zoomScale = 1.0;
  bool _isWireframe = false;
  bool _isAncientReconstruction = true;
  Hotspot3D? _selectedHotspot;
  bool _isNarrating = false;
  String? _narrationText;

  @override
  void initState() {
    super.initState();
    _currentLandmark = widget.initialLandmark ??
        Heritage3DLandmark.sampleHeritageModels.first;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Start with cultural guide welcome
    _narrationText = _currentLandmark.virtualGuideWelcome;
    _isNarrating = true;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _selectLandmark(Heritage3DLandmark landmark) {
    setState(() {
      _currentLandmark = landmark;
      _selectedHotspot = null;
      _narrationText = landmark.virtualGuideWelcome;
      _isNarrating = true;
      _rotationX = 0.35;
      _rotationY = -0.55;
      _zoomScale = 1.0;
    });
  }

  void _toggleNarration() {
    setState(() {
      _isNarrating = !_isNarrating;
    });
  }

  void _openARSurfacePlacement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CulturalArCameraPage(
          initialLandmark: Landmark(
            id: _currentLandmark.id,
            name: _currentLandmark.name,
            description: _currentLandmark.description,
            latitude: 0,
            longitude: 0,
            city: _currentLandmark.location,
            site3dModelUrl: _currentLandmark.glbModelUrl,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : const Color(0xFF1A1D24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentLandmark.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${_currentLandmark.amharicName} • ${_currentLandmark.period}',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade300),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isWireframe ? 'Shaded 3D Mode' : 'Wireframe 3D Mode',
            icon: Icon(_isWireframe ? Icons.view_in_ar : Icons.grid_4x4, color: Colors.white70),
            onPressed: () => setState(() => _isWireframe = !_isWireframe),
          ),
          IconButton(
            tooltip: 'Place in Real World AR',
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.amberAccent),
            onPressed: _openARSurfacePlacement,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Interactive 3D Canvas
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                if (details.scale != 1.0) {
                  _zoomScale = (_zoomScale * details.scale).clamp(0.6, 2.4);
                } else {
                  _rotationY += details.focalPointDelta.dx * 0.01;
                  _rotationX = (_rotationX - details.focalPointDelta.dy * 0.01)
                      .clamp(-math.pi / 2.2, math.pi / 2.2);
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: Heritage3DCanvasPainter(
                  landmarkId: _currentLandmark.id,
                  rotationX: _rotationX,
                  rotationY: _rotationY,
                  zoom: _zoomScale,
                  isWireframe: _isWireframe,
                  isAncientReconstruction: _isAncientReconstruction,
                  hotspots: _currentLandmark.hotspots,
                  selectedHotspot: _selectedHotspot,
                  onHotspotHit: (hotspot) {
                    setState(() {
                      _selectedHotspot = hotspot;
                      _narrationText = hotspot.audioScript;
                      _isNarrating = true;
                    });
                  },
                ),
              ),
            ),
          ),

          // 2. Top Time-Machine Toggle (Ancient vs Modern)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTimeTab(
                      label: 'Ancient Reconstruction',
                      icon: Icons.history_edu,
                      selected: _isAncientReconstruction,
                      onTap: () => setState(() => _isAncientReconstruction = true),
                    ),
                    const SizedBox(width: 4),
                    _buildTimeTab(
                      label: 'Modern Preservation',
                      icon: Icons.verified_outlined,
                      selected: !_isAncientReconstruction,
                      onTap: () => setState(() => _isAncientReconstruction = false),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 3D Controls Overlay (Reset & Zoom Hint)
          Positioned(
            right: 16,
            top: 70,
            child: Column(
              children: [
                _buildCircleIconButton(
                  icon: Icons.refresh,
                  tooltip: 'Reset 3D View',
                  onTap: () {
                    setState(() {
                      _rotationX = 0.35;
                      _rotationY = -0.55;
                      _zoomScale = 1.0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _buildCircleIconButton(
                  icon: Icons.zoom_in,
                  tooltip: 'Zoom In',
                  onTap: () => setState(() => _zoomScale = (_zoomScale + 0.2).clamp(0.6, 2.4)),
                ),
                const SizedBox(height: 10),
                _buildCircleIconButton(
                  icon: Icons.zoom_out,
                  tooltip: 'Zoom Out',
                  onTap: () => setState(() => _zoomScale = (_zoomScale - 0.2).clamp(0.6, 2.4)),
                ),
                const SizedBox(height: 10),
                _buildCircleIconButton(
                  icon: Icons.view_in_ar,
                  tooltip: 'AR Camera',
                  accent: true,
                  onTap: _openARSurfacePlacement,
                ),
              ],
            ),
          ),

          // 4. Bottom Sheets & Landmark Carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Active Hotspot or Narration Card
                  _buildNarrationAndHotspotCard(),
                  const SizedBox(height: 8),

                  // Heritage Models Carousel Switcher
                  _buildHeritageCarousel(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? EthioColors.terracotta : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool accent = false,
  }) {
    return Material(
      color: accent ? EthioColors.forest : Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildNarrationAndHotspotCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guide Header & Voice Bar
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: EthioColors.gold.withValues(alpha: 0.2),
                child: const Text('🇪🇹', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Selam • Cultural AR Storyteller',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedHotspot != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: EthioColors.terracotta,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HOTSPOT',
                              style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _selectedHotspot != null
                          ? _selectedHotspot!.title
                          : (_isAncientReconstruction
                              ? 'Golden Era Architectural View'
                              : 'Modern Structural Status'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isNarrating ? Icons.volume_up : Icons.volume_off,
                  color: _isNarrating ? Colors.amberAccent : Colors.white38,
                  size: 20,
                ),
                onPressed: _toggleNarration,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Narration description
          Text(
            _selectedHotspot != null
                ? _selectedHotspot!.description
                : (_isAncientReconstruction
                    ? _currentLandmark.ancientReconstructionNote
                    : _currentLandmark.modernPreservationNote),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.45,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeritageCarousel() {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Heritage3DLandmark.sampleHeritageModels.length,
        itemBuilder: (context, idx) {
          final model = Heritage3DLandmark.sampleHeritageModels[idx];
          final isSelected = model.id == _currentLandmark.id;

          return GestureDetector(
            onTap: () => _selectLandmark(model),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? EthioColors.terracotta.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? EthioColors.terracotta : Colors.white12,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      model.thumbnailUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 44,
                        height: 44,
                        color: EthioColors.slate,
                        child: const Icon(Icons.castle, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          model.amharicName,
                          style: TextStyle(color: Colors.amber.shade200, fontSize: 10),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 3D Vector Math & Rendering Canvas for Ethiopian Architectural Heritage
class Heritage3DCanvasPainter extends CustomPainter {
  final String landmarkId;
  final double rotationX;
  final double rotationY;
  final double zoom;
  final bool isWireframe;
  final bool isAncientReconstruction;
  final List<Hotspot3D> hotspots;
  final Hotspot3D? selectedHotspot;
  final ValueChanged<Hotspot3D> onHotspotHit;

  Heritage3DCanvasPainter({
    required this.landmarkId,
    required this.rotationX,
    required this.rotationY,
    required this.zoom,
    required this.isWireframe,
    required this.isAncientReconstruction,
    required this.hotspots,
    required this.selectedHotspot,
    required this.onHotspotHit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 30; // slightly offset for bottom cards

    // 1. Draw glowing ground grid
    _drawGroundGrid(canvas, cx, cy, size);

    // 2. Render 3D Model Primitives based on monument type
    if (landmarkId == 'lalibela-bete-giyorgis') {
      _drawBeteGiyorgisCross(canvas, cx, cy);
    } else if (landmarkId == 'axum-obelisk') {
      _drawAxumObelisk(canvas, cx, cy);
    } else if (landmarkId == 'fasil-ghebbi') {
      _drawFasilGhebbiCastle(canvas, cx, cy);
    } else {
      _drawLucyHominidSkeleton(canvas, cx, cy);
    }

    // 3. Render 3D Hotspot Pins in world space
    _drawHotspots(canvas, cx, cy);
  }

  void _drawGroundGrid(Canvas canvas, double cx, double cy, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (int i = -4; i <= 4; i++) {
      final p1 = _project3D(i * 35.0, -90.0, -140.0, cx, cy);
      final p2 = _project3D(i * 35.0, -90.0, 140.0, cx, cy);
      canvas.drawLine(p1, p2, gridPaint);

      final p3 = _project3D(-140.0, -90.0, i * 35.0, cx, cy);
      final p4 = _project3D(140.0, -90.0, i * 35.0, cx, cy);
      canvas.drawLine(p3, p4, gridPaint);
    }
  }

  void _drawBeteGiyorgisCross(Canvas canvas, double cx, double cy) {
    final baseColor = isAncientReconstruction
        ? const Color(0xFFC76D52) // Vibrant Ethiopian red volcanic tuff
        : const Color(0xFF8B5E4F); // Weathered aged stone

    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: isWireframe ? 0.15 : 0.85)
      ..style = isWireframe ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1.5;

    final strokePaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw the 12-meter surrounding trench
    final trenchPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final trenchP1 = _project3D(-110, -90, -110, cx, cy);
    final trenchP2 = _project3D(110, -90, -110, cx, cy);
    final trenchP3 = _project3D(110, -90, 110, cx, cy);
    final trenchP4 = _project3D(-110, -90, 110, cx, cy);
    final trenchPath = Path()
      ..moveTo(trenchP1.dx, trenchP1.dy)
      ..lineTo(trenchP2.dx, trenchP2.dy)
      ..lineTo(trenchP3.dx, trenchP3.dy)
      ..lineTo(trenchP4.dx, trenchP4.dy)
      ..close();
    canvas.drawPath(trenchPath, trenchPaint);

    // Cross geometry segments:
    // Core center box + 4 cross arms (North, South, East, West)
    final h = 100.0; // Height of monolith
    final arm = 32.0;

    _drawBox(canvas, cx, cy, 0, 0, arm, arm, h, fillPaint, strokePaint);
    _drawBox(canvas, cx, cy, 0, arm, arm, arm, h, fillPaint, strokePaint);
    _drawBox(canvas, cx, cy, 0, -arm, arm, arm, h, fillPaint, strokePaint);
    _drawBox(canvas, cx, cy, arm, 0, arm, arm, h, fillPaint, strokePaint);
    _drawBox(canvas, cx, cy, -arm, 0, arm, arm, h, fillPaint, strokePaint);

    // Triple Nested Greek Cross on top
    final topP = _project3D(0, h / 2 + 1, 0, cx, cy);
    final crossDeco = Paint()
      ..color = Colors.amber.shade300
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final c1 = _project3D(-arm * 1.2, h / 2 + 2, 0, cx, cy);
    final c2 = _project3D(arm * 1.2, h / 2 + 2, 0, cx, cy);
    final c3 = _project3D(0, h / 2 + 2, -arm * 1.2, cx, cy);
    final c4 = _project3D(0, h / 2 + 2, arm * 1.2, cx, cy);
    canvas.drawLine(c1, c2, crossDeco);
    canvas.drawLine(c3, c4, crossDeco);
  }

  void _drawAxumObelisk(Canvas canvas, double cx, double cy) {
    final graniteColor = isAncientReconstruction
        ? const Color(0xFFB5BAC9) // Gleaming ancient granodiorite
        : const Color(0xFF6B7280); // Modern weathered stone

    final fillPaint = Paint()
      ..color = graniteColor.withValues(alpha: isWireframe ? 0.15 : 0.9)
      ..style = isWireframe ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1.5;

    final strokePaint = Paint()
      ..color = Colors.amber.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Tapered Stele Tower (10 Storeys)
    final totalH = 180.0;
    _drawTaperedTower(canvas, cx, cy, totalH, 36.0, 22.0, fillPaint, strokePaint);

    // Gilded Apex at top
    final apexP = _project3D(0, totalH / 2 + 10, 0, cx, cy);
    final goldPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    canvas.drawCircle(apexP, 10 * zoom, goldPaint);

    // Carved false doorway at base
    final doorBase = _project3D(0, -totalH / 2 + 15, 18, cx, cy);
    final doorPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromCenter(center: doorBase, width: 14 * zoom, height: 22 * zoom),
      doorPaint,
    );
  }

  void _drawFasilGhebbiCastle(Canvas canvas, double cx, double cy) {
    final stoneColor = isAncientReconstruction
        ? const Color(0xFF9E7854) // Rich brown basalt and brown sandstone
        : const Color(0xFF6B5848);

    final fillPaint = Paint()
      ..color = stoneColor.withValues(alpha: isWireframe ? 0.2 : 0.85)
      ..style = isWireframe ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1.5;

    final strokePaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Main 3-storey castle block
    _drawBox(canvas, cx, cy, 0, 0, 80, 60, 90, fillPaint, strokePaint);

    // 4 Corner Watchtower Turrets
    final r = 38.0;
    _drawTurret(canvas, cx, cy, -r, -r, 110, 16, fillPaint, strokePaint);
    _drawTurret(canvas, cx, cy, r, -r, 110, 16, fillPaint, strokePaint);
    _drawTurret(canvas, cx, cy, -r, r, 110, 16, fillPaint, strokePaint);
    _drawTurret(canvas, cx, cy, r, r, 110, 16, fillPaint, strokePaint);
  }

  void _drawLucyHominidSkeleton(Canvas canvas, double cx, double cy) {
    final boneColor = isAncientReconstruction
        ? const Color(0xFFE2C9A5) // Polished ivory bone fossil
        : const Color(0xFF9B8770);

    final bonePaint = Paint()
      ..color = boneColor
      ..strokeWidth = 4.0 * zoom
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;

    // Spine
    final head = _project3D(0, 70, 0, cx, cy);
    final neck = _project3D(0, 50, 0, cx, cy);
    final pelvis = _project3D(0, 0, 0, cx, cy);
    canvas.drawLine(head, neck, bonePaint);
    canvas.drawLine(neck, pelvis, bonePaint);
    canvas.drawCircle(head, 14 * zoom, jointPaint);

    // Pelvic Bowl
    final pLeft = _project3D(-20, 0, 0, cx, cy);
    final pRight = _project3D(20, 0, 0, cx, cy);
    canvas.drawLine(pLeft, pRight, bonePaint);

    // Legs (Bipedal structure)
    final kLeft = _project3D(-16, -45, 10, cx, cy);
    final kRight = _project3D(16, -45, -10, cx, cy);
    final fLeft = _project3D(-16, -85, 15, cx, cy);
    final fRight = _project3D(16, -85, -5, cx, cy);

    canvas.drawLine(pLeft, kLeft, bonePaint);
    canvas.drawLine(kLeft, fLeft, bonePaint);
    canvas.drawLine(pRight, kRight, bonePaint);
    canvas.drawLine(kRight, fRight, bonePaint);

    // Arms
    final sLeft = _project3D(-24, 45, 0, cx, cy);
    final sRight = _project3D(24, 45, 0, cx, cy);
    final hLeft = _project3D(-32, 10, 10, cx, cy);
    final hRight = _project3D(32, 10, -10, cx, cy);

    canvas.drawLine(neck, sLeft, bonePaint);
    canvas.drawLine(sLeft, hLeft, bonePaint);
    canvas.drawLine(neck, sRight, bonePaint);
    canvas.drawLine(sRight, hRight, bonePaint);
  }

  void _drawBox(
    Canvas canvas,
    double cx,
    double cy,
    double x,
    double z,
    double w,
    double d,
    double h,
    Paint fill,
    Paint stroke,
  ) {
    final hw = w / 2;
    final hd = d / 2;
    final hh = h / 2;

    final p0 = _project3D(x - hw, -hh, z - hd, cx, cy);
    final p1 = _project3D(x + hw, -hh, z - hd, cx, cy);
    final p2 = _project3D(x + hw, -hh, z + hd, cx, cy);
    final p3 = _project3D(x - hw, -hh, z + hd, cx, cy);

    final p4 = _project3D(x - hw, hh, z - hd, cx, cy);
    final p5 = _project3D(x + hw, hh, z - hd, cx, cy);
    final p6 = _project3D(x + hw, hh, z + hd, cx, cy);
    final p7 = _project3D(x - hw, hh, z + hd, cx, cy);

    _drawQuad(canvas, p0, p1, p5, p4, fill, stroke);
    _drawQuad(canvas, p1, p2, p6, p5, fill, stroke);
    _drawQuad(canvas, p2, p3, p7, p6, fill, stroke);
    _drawQuad(canvas, p3, p0, p4, p7, fill, stroke);
    _drawQuad(canvas, p4, p5, p6, p7, fill, stroke);
  }

  void _drawTaperedTower(
    Canvas canvas,
    double cx,
    double cy,
    double h,
    double baseW,
    double topW,
    Paint fill,
    Paint stroke,
  ) {
    final hb = baseW / 2;
    final ht = topW / 2;
    final hh = h / 2;

    final p0 = _project3D(-hb, -hh, -hb, cx, cy);
    final p1 = _project3D(hb, -hh, -hb, cx, cy);
    final p2 = _project3D(hb, -hh, hb, cx, cy);
    final p3 = _project3D(-hb, -hh, hb, cx, cy);

    final p4 = _project3D(-ht, hh, -ht, cx, cy);
    final p5 = _project3D(ht, hh, -ht, cx, cy);
    final p6 = _project3D(ht, hh, ht, cx, cy);
    final p7 = _project3D(-ht, hh, ht, cx, cy);

    _drawQuad(canvas, p0, p1, p5, p4, fill, stroke);
    _drawQuad(canvas, p1, p2, p6, p5, fill, stroke);
    _drawQuad(canvas, p2, p3, p7, p6, fill, stroke);
    _drawQuad(canvas, p3, p0, p4, p7, fill, stroke);
    _drawQuad(canvas, p4, p5, p6, p7, fill, stroke);
  }

  void _drawTurret(
    Canvas canvas,
    double cx,
    double cy,
    double x,
    double z,
    double h,
    double rad,
    Paint fill,
    Paint stroke,
  ) {
    _drawBox(canvas, cx, cy, x, z, rad, rad, h, fill, stroke);
    // Domed cupola top
    final dome = _project3D(x, h / 2 + 6, z, cx, cy);
    canvas.drawCircle(dome, (rad / 2) * zoom, fill);
    canvas.drawCircle(dome, (rad / 2) * zoom, stroke);
  }

  void _drawQuad(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawHotspots(Canvas canvas, double cx, double cy) {
    for (final hotspot in hotspots) {
      // Map normalized -1.0 to 1.0 to 3D world space
      final wx = hotspot.x * 70.0;
      final wy = hotspot.y * 60.0;
      final wz = hotspot.z * 70.0;

      final p = _project3D(wx, wy, wz, cx, cy);
      final isSelected = selectedHotspot?.id == hotspot.id;

      // Outer pulsing ring
      final ringPaint = Paint()
        ..color = (isSelected ? Colors.amberAccent : EthioColors.terracotta)
            .withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, (isSelected ? 16 : 11) * zoom, ringPaint);

      // Core pin dot
      final dotPaint = Paint()
        ..color = isSelected ? Colors.amberAccent : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 5.0 * zoom, dotPaint);

      // White outline
      final borderPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(p, 5.0 * zoom, borderPaint);
    }
  }

  Offset _project3D(double x, double y, double z, double cx, double cy) {
    // 1. Rotate around Y axis
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final x1 = x * cosY - z * sinY;
    final z1 = z * cosY + x * sinY;

    // 2. Rotate around X axis (pitch)
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final y2 = y * cosX - z1 * sinX;
    final z2 = z1 * cosX + y * sinX;

    // 3. Perspective Projection
    const cameraDistance = 350.0;
    final perspective = cameraDistance / (cameraDistance + z2);

    final px = cx + x1 * perspective * zoom;
    final py = cy - y2 * perspective * zoom; // invert Y for screen coords

    return Offset(px, py);
  }

  @override
  bool shouldRepaint(covariant Heritage3DCanvasPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.isWireframe != isWireframe ||
        oldDelegate.isAncientReconstruction != isAncientReconstruction ||
        oldDelegate.selectedHotspot != selectedHotspot ||
        oldDelegate.landmarkId != landmarkId;
  }
}
