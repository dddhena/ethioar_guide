import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Realistic Rope / Reins Painter
/// Draws a flexible hemp/leather lead rope between the animal's halter/bridle
/// and the user's hand with dynamic catenary droop, texture, and drop shadow.
class RopeLeashPainter extends CustomPainter {
  final Offset animalAnchor; // e.g. Horse bridle / collar point
  final Offset handAnchor;   // e.g. User hand grip point
  final double droopFactor;  // Natural gravity sag
  final Color ropeColor;
  final bool animateSag;
  final double animationValue;

  RopeLeashPainter({
    required this.animalAnchor,
    required this.handAnchor,
    this.droopFactor = 0.22,
    this.ropeColor = const Color(0xFF8D5B4C), // Leather brown / hemp
    this.animateSag = true,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If either point is outside or undefined, skip
    if (animalAnchor.dx == 0 && animalAnchor.dy == 0) return;
    if (handAnchor.dx == 0 && handAnchor.dy == 0) return;

    final dx = handAnchor.dx - animalAnchor.dx;
    final dy = handAnchor.dy - animalAnchor.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance < 5) return;

    // Subtle breath / swing oscillation
    final oscillation = animateSag ? math.sin(animationValue * 2 * math.pi) * 6.0 : 0.0;
    final sag = (distance * droopFactor) + oscillation;

    // Midpoint with gravity drop
    final midX = (animalAnchor.dx + handAnchor.dx) / 2;
    final midY = (animalAnchor.dy + handAnchor.dy) / 2 + sag;
    final controlPoint = Offset(midX, midY);

    final path = Path()
      ..moveTo(animalAnchor.dx, animalAnchor.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, handAnchor.dx, handAnchor.dy);

    // 1. Drop shadow for depth against real-world camera
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final shadowPath = Path()
      ..moveTo(animalAnchor.dx + 4, animalAnchor.dy + 8)
      ..quadraticBezierTo(controlPoint.dx + 4, controlPoint.dy + 8, handAnchor.dx + 4, handAnchor.dy + 8);

    canvas.drawPath(shadowPath, shadowPaint);

    // 2. Base thick leather/hemp rope
    final ropeBasePaint = Paint()
      ..color = ropeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, ropeBasePaint);

    // 3. Highlight braid line for 3D realism
    final ropeHighlightPaint = Paint()
      ..color = const Color(0xFFD7A764).withValues(alpha: 0.75) // Golden highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, ropeHighlightPaint);

    // 4. Animal Bridle Ring / Halter Knot at animal anchor
    final knotPaint = Paint()
      ..color = const Color(0xFFB8860B) // Brass buckle
      ..style = PaintingStyle.fill;

    canvas.drawCircle(animalAnchor, 5.0, knotPaint);
    canvas.drawCircle(
      animalAnchor,
      3.0,
      Paint()
        ..color = Colors.black38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 5. User Hand Grip Indicator / Ring
    final gripPaint = Paint()
      ..color = const Color(0xFFD4AF37) // Gold grip ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(handAnchor, 9.0, gripPaint);
    canvas.drawCircle(
      handAnchor,
      4.0,
      Paint()..color = const Color(0xFF8D5B4C),
    );
  }

  @override
  bool shouldRepaint(covariant RopeLeashPainter oldDelegate) {
    return oldDelegate.animalAnchor != animalAnchor ||
        oldDelegate.handAnchor != handAnchor ||
        oldDelegate.animationValue != animationValue;
  }
}
