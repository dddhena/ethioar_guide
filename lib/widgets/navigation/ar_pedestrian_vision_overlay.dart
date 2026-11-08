import 'package:flutter/material.dart';
import '../../models/pedestrian_detected_object.dart';

/// Renders interactive AR bounding boxes, door frames, distance reticles,
/// and magnetic target guides on top of the live camera view.
class ArPedestrianVisionOverlay extends StatelessWidget {
  final List<PedestrianDetectedObject> detectedObjects;
  final double pulseValue;
  final Function(PedestrianDetectedObject)? onObjectTapped;

  const ArPedestrianVisionOverlay({
    super.key,
    required this.detectedObjects,
    this.pulseValue = 0.5,
    this.onObjectTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (detectedObjects.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Draw Connecting Laser / Guide Line from Ground to Target Door
            CustomPaint(
              painter: _ArDoorGuideConnectingPainter(
                detectedObjects: detectedObjects,
                pulse: pulseValue,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
              size: Size(screenWidth, screenHeight),
            ),

            // 2. Render each detected physical element (doors, gates, stairs, crosswalks)
            for (final obj in detectedObjects)
              _buildObjectBox(context, obj, screenWidth, screenHeight),
          ],
        );
      },
    );
  }

  Widget _buildObjectBox(
    BuildContext context,
    PedestrianDetectedObject obj,
    double screenWidth,
    double screenHeight,
  ) {
    final left = obj.normalizedRect.left * screenWidth;
    final top = obj.normalizedRect.top * screenHeight;
    final width = obj.normalizedRect.width * screenWidth;
    final height = obj.normalizedRect.height * screenHeight;

    final isTarget = obj.isNavigationTarget;
    final accentColor = obj.accentColor;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => onObjectTapped?.call(obj),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // AR Door Frame Glowing Border with animated pulse
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.75 + pulseValue * 0.25),
                  width: isTarget ? 2.5 : 1.5,
                ),
                color: accentColor.withValues(alpha: isTarget ? 0.08 : 0.04),
                boxShadow: isTarget
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),

            // Corner Reticles for High-Tech AR Viewfinder feel
            Positioned.fill(
              child: CustomPaint(
                painter: _CornerBracketsPainter(
                  color: accentColor,
                  bracketLength: 16.0,
                  bracketWidth: 3.0,
                ),
              ),
            ),

            // Top Floating Object Badge (Icon + Label + Distance)
            Positioned(
              top: -34,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor,
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(obj.iconData, size: 14, color: accentColor),
                      const SizedBox(width: 5),
                      Text(
                        obj.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          obj.formattedDistance,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center Target Crosshair (if this is the target door)
            if (isTarget)
              Center(
                child: Container(
                  width: 32 + pulseValue * 8,
                  height: 32 + pulseValue * 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom Action Guidance Tag
            Positioned(
              bottom: -26,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '➜ ${obj.actionGuidance}',
                    style: TextStyle(
                      color: isTarget ? Colors.greenAccent : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the high-precision corner brackets around the detected door/object
class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double bracketLength;
  final double bracketWidth;

  _CornerBracketsPainter({
    required this.color,
    required this.bracketLength,
    required this.bracketWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = bracketWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), Offset(bracketLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, bracketLength), paint);

    // Top-Right
    canvas.drawLine(Offset(w, 0), Offset(w - bracketLength, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, bracketLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, h), Offset(bracketLength, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - bracketLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(w, h), Offset(w - bracketLength, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.bracketLength != bracketLength ||
      oldDelegate.bracketWidth != bracketWidth;
}

/// Draws an animated magnetic AR beam connecting the ground arrows to the target door
class _ArDoorGuideConnectingPainter extends CustomPainter {
  final List<PedestrianDetectedObject> detectedObjects;
  final double pulse;
  final double screenWidth;
  final double screenHeight;

  _ArDoorGuideConnectingPainter({
    required this.detectedObjects,
    required this.pulse,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Find target door or entrance
    final targets = detectedObjects.where((o) => o.isNavigationTarget).toList();
    if (targets.isEmpty) return;

    final target = targets.first;
    final targetCenter = Offset(
      (target.normalizedRect.left + target.normalizedRect.right) / 2.0 * screenWidth,
      target.normalizedRect.bottom * screenHeight, // connect at door threshold base
    );

    final groundOrigin = Offset(screenWidth / 2, screenHeight * 0.72);

    final beamPaint = Paint()
      ..color = target.accentColor.withValues(alpha: 0.35 + pulse * 0.25)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(groundOrigin.dx, groundOrigin.dy);
    path.quadraticBezierTo(
      screenWidth / 2,
      (groundOrigin.dy + targetCenter.dy) / 2,
      targetCenter.dx,
      targetCenter.dy,
    );

    canvas.drawPath(path, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _ArDoorGuideConnectingPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.detectedObjects != detectedObjects;
}
