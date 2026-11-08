import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/ethio_theme.dart';

/// Lightweight, crash-proof AR camera background view used for real-time
/// AR navigation and immersive attraction experiences.
///
/// If a live [cameraController] is provided and initialized, it renders the
/// real-time hardware camera viewfinder covering the entire screen.
/// If camera hardware is unavailable, initializing, or denied, it gracefully
/// falls back to a smooth high-fidelity AR spatial canvas with horizon alignment
/// and viewfinder reticles so navigation never crashes.
class ArCameraBackgroundView extends StatefulWidget {
  final CameraController? cameraController;
  final bool isCameraReady;
  final String? overlayTitle;
  final bool showScanEffect;
  final bool autoInitCamera;

  const ArCameraBackgroundView({
    super.key,
    this.cameraController,
    this.isCameraReady = false,
    this.overlayTitle,
    this.showScanEffect = true,
    this.autoInitCamera = false,
  });

  @override
  State<ArCameraBackgroundView> createState() => _ArCameraBackgroundViewState();
}

class _ArCameraBackgroundViewState extends State<ArCameraBackgroundView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  CameraController? _internalCameraController;
  bool _isInternalCameraReady = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    if (widget.autoInitCamera && widget.cameraController == null) {
      _initFallbackInternalCamera();
    }
  }

  Future<void> _initFallbackInternalCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty && mounted) {
        final backCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        _internalCameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _internalCameraController!.initialize();
        if (mounted) {
          setState(() {
            _isInternalCameraReady = true;
          });
        }
      }
    } catch (_) {
      // Graceful fallback to simulated AR spatial grid
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _internalCameraController?.dispose();
    super.dispose();
  }

  CameraController? get _activeController =>
      widget.cameraController ?? _internalCameraController;

  bool get _isReady =>
      (widget.cameraController != null && widget.isCameraReady) ||
      (_internalCameraController != null && _isInternalCameraReady);

  @override
  Widget build(BuildContext context) {
    final controller = _activeController;
    final bool hasLiveCamera = _isReady &&
        controller != null &&
        controller.value.isInitialized;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Hardware Camera Viewfinder (Full Screen Aspect Ratio)
          if (hasLiveCamera)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize?.height ?? 1,
                  height: controller.value.previewSize?.width ?? 1,
                  child: CameraPreview(controller),
                ),
              ),
            )
          else
            // Fallback Simulated Spatial Canvas
            _buildSimulatedCanvas(),

          // 2. Subtle Darkening Gradient Vignette for high-contrast AR HUD
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Animated Spatial Scanning Grid & Horizon (Subtle on live camera)
          if (widget.showScanEffect)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ArScanningCanvasPainter(
                    progress: _scanController.value,
                    isLiveCamera: hasLiveCamera,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // 4. Viewfinder Corner Reticles
          const Positioned.fill(
            child: _ArViewfinderCorners(),
          ),

          // 5. Sensor Status Indicator Badge (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasLiveCamera ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.amberAccent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasLiveCamera ? Colors.greenAccent : Colors.amberAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasLiveCamera ? 'LIVE CAMERA AR' : 'SPATIAL SIMULATOR',
                    style: TextStyle(
                      color: hasLiveCamera ? Colors.greenAccent : Colors.amberAccent,
                      fontSize: 9,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedCanvas() {
    return Container(
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
    );
  }
}

class _ArScanningCanvasPainter extends CustomPainter {
  final double progress;
  final bool isLiveCamera;

  _ArScanningCanvasPainter({
    required this.progress,
    this.isLiveCamera = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.50;

    // Moving horizontal scan sweep line
    final sweepY = horizonY + (progress * (h - horizonY));
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          (isLiveCamera ? Colors.greenAccent : EthioColors.forestLight).withValues(alpha: isLiveCamera ? 0.25 : 0.40),
          Colors.cyanAccent.withValues(alpha: isLiveCamera ? 0.35 : 0.50),
          (isLiveCamera ? Colors.greenAccent : EthioColors.forestLight).withValues(alpha: isLiveCamera ? 0.25 : 0.40),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, sweepY - 1, w, 3))
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(0, sweepY), Offset(w, sweepY), sweepPaint);

    // If simulated canvas, also draw ground perspective grid
    if (!isLiveCamera) {
      final gridPaint = Paint()
        ..color = EthioColors.forestLight.withValues(alpha: 0.10)
        ..strokeWidth = 1.0;

      final horizonPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.15)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(0, horizonY), Offset(w, horizonY), horizonPaint);

      final vanishX = w / 2;
      for (int i = -4; i <= 4; i++) {
        final bottomX = vanishX + (i * (w / 3.5));
        canvas.drawLine(
          Offset(vanishX, horizonY),
          Offset(bottomX, h),
          gridPaint,
        );
      }
    }

    // Center focal crosshair dots
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, horizonY), 3.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ArScanningCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isLiveCamera != isLiveCamera;
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
      ..color = Colors.white.withValues(alpha: 0.25)
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
  bool shouldRepaint(covariant _CornersPainter oldDelegate) => false;
}
