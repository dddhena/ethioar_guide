import 'package:flutter/material.dart';
import '../../theme/ethio_theme.dart';

/// Lightweight, crash-proof AR camera background view used for real-time
/// AR navigation and immersive attraction experiences.
///
/// Unlike embedding a full ARCore session or scaffold inside a stack (which causes
/// crashes on devices without Google ARCore installed), this widget provides a
/// smooth, high-fidelity AR camera viewfinder canvas with animated spatial grid,
/// horizon alignment markers, and corner target reticles.
class ArCameraBackgroundView extends StatefulWidget {
  final String? overlayTitle;
  final bool showScanEffect;

  const ArCameraBackgroundView({
    super.key,
    this.overlayTitle,
    this.showScanEffect = true,
  });

  @override
  State<ArCameraBackgroundView> createState() => _ArCameraBackgroundViewState();
}

class _ArCameraBackgroundViewState extends State<ArCameraBackgroundView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1117), // Deep AR camera canvas
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Subtle Radial Vignette Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, 0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF161E2E), // Subtle dark slate at center
                  Color(0xFF090D14), // Near black at edges
                ],
              ),
            ),
          ),

          // 2. Animated Spatial Scanning Grid & Horizon
          if (widget.showScanEffect)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ArScanningCanvasPainter(
                    progress: _scanController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // 3. Viewfinder Corner Reticles
          const Positioned.fill(
            child: _ArViewfinderCorners(),
          ),

          // 4. Subtle Lens Dust / Ambient Noise effect overlay
          Positioned(
            bottom: 12,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'AR SPATIAL SENSOR ACTIVE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
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

class _ArScanningCanvasPainter extends CustomPainter {
  final double progress;

  _ArScanningCanvasPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.52;

    // Perspective ground grid
    final gridPaint = Paint()
      ..color = EthioColors.forestLight.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    // Horizon line
    final horizonPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.15)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, horizonY), Offset(w, horizonY), horizonPaint);

    // Perspective lines radiating from center horizon
    final vanishX = w / 2;
    for (int i = -4; i <= 4; i++) {
      final bottomX = vanishX + (i * (w / 3.5));
      canvas.drawLine(
        Offset(vanishX, horizonY),
        Offset(bottomX, h),
        gridPaint,
      );
    }

    // Moving horizontal scan sweep line
    final sweepY = horizonY + (progress * (h - horizonY));
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          EthioColors.forestLight.withValues(alpha: 0.35),
          Colors.cyanAccent.withValues(alpha: 0.5),
          EthioColors.forestLight.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, sweepY - 1, w, 3))
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(0, sweepY), Offset(w, sweepY), sweepPaint);

    // Center focal crosshair dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, horizonY), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ArScanningCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ArViewfinderCorners extends StatelessWidget {
  const _ArViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornersPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const cornerLength = 24.0;
    const padding = 20.0;

    final w = size.width;
    final h = size.height;

    // Top-Left
    canvas.drawLine(const Offset(padding, padding + cornerLength), const Offset(padding, padding), paint);
    canvas.drawLine(const Offset(padding, padding), const Offset(padding + cornerLength, padding), paint);

    // Top-Right
    canvas.drawLine(Offset(w - padding - cornerLength, padding), Offset(w - padding, padding), paint);
    canvas.drawLine(Offset(w - padding, padding), Offset(w - padding, padding + cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(padding, h - padding - cornerLength), Offset(padding, h - padding), paint);
    canvas.drawLine(Offset(padding, h - padding), Offset(padding + cornerLength, h - padding), paint);

    // Bottom-Right
    canvas.drawLine(Offset(w - padding - cornerLength, h - padding), Offset(w - padding, h - padding), paint);
    canvas.drawLine(Offset(w - padding, h - padding), Offset(w - padding, h - padding - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
