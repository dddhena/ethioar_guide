import 'package:flutter/material.dart';
import '../../models/landmark.dart';

/// Cultural Attire Dress-Up Overlay (Snapchat-style virtual try-on)
/// Provides interactive pan, pinch-to-scale, and realistic decorative Ethiopian heritage garments.
class CulturalAttireOverlay extends StatefulWidget {
  final CulturalAttire attire;
  final bool isInteractive;
  final VoidCallback? onResetPosition;

  const CulturalAttireOverlay({
    super.key,
    required this.attire,
    this.isInteractive = true,
    this.onResetPosition,
  });

  @override
  State<CulturalAttireOverlay> createState() => _CulturalAttireOverlayState();
}

class _CulturalAttireOverlayState extends State<CulturalAttireOverlay> {
  Offset _offset = const Offset(0, 110);
  double _scale = 1.0;
  double _baseScale = 1.0;

  @override
  void didUpdateWidget(covariant CulturalAttireOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attire.id != widget.attire.id) {
      // Re-center on attire change
      setState(() {
        _offset = const Offset(0, 110);
        _scale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: (screenSize.width / 2 - 160) + _offset.dx,
      top: (screenSize.height / 2 - 140) + _offset.dy,
      child: GestureDetector(
        onScaleStart: widget.isInteractive
            ? (details) {
                _baseScale = _scale;
              }
            : null,
        onScaleUpdate: widget.isInteractive
            ? (details) {
                setState(() {
                  _scale = (_baseScale * details.scale).clamp(0.6, 2.2);
                  _offset += details.focalPointDelta;
                });
              }
            : null,
        child: Transform.scale(
          scale: _scale,
          child: SizedBox(
            width: 320,
            height: 380,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Render stylized high-detail vector heritage attire
                _buildAttireGraphic(widget.attire),

                // Subtle alignment boundary indicator while adjusting
                if (widget.isInteractive)
                  Positioned(
                    top: -24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, size: 12, color: Colors.amberAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Drag or pinch to fit ${widget.attire.name}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttireGraphic(CulturalAttire attire) {
    final photoUrl = attire.overlayUrl.isNotEmpty && attire.overlayUrl.startsWith('http')
        ? attire.overlayUrl
        : (attire.previewUrl.isNotEmpty && attire.previewUrl.startsWith('http') ? attire.previewUrl : '');

    if (photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          photoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackVector(attire),
        ),
      );
    }
    return _buildFallbackVector(attire);
  }

  Widget _buildFallbackVector(CulturalAttire attire) {
    switch (attire.id) {
      case 'kaba_royal_gold':
        return const _RoyalKabaGraphic();
      case 'habesha_kemis_shewa':
        return const _HabeshaKemisGraphic();
      case 'oromo_traditional_attire':
        return const _OromoAttireGraphic();
      case 'netela_gabi_shawl':
      default:
        return const _NetelaShawlGraphic();
    }
  }
}

/// 1. Royal Imperial Kaba (የንግሥት/ንጉሥ ካባ)
/// Deep velvet cloak with intricate gold embroidery and royal collar
class _RoyalKabaGraphic extends StatelessWidget {
  const _RoyalKabaGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 380),
      painter: _RoyalKabaPainter(),
    );
  }
}

class _RoyalKabaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Cloak fabric (Royal Deep Maroon/Black Velvet)
    final cloakPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3F0B14), Color(0xFF1F050A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Cloak Cutout Path (Shoulders & Draped Torso)
    final path = Path()
      ..moveTo(size.width * 0.32, 20) // Left collar
      ..quadraticBezierTo(size.width * 0.5, 48, size.width * 0.68, 20) // Neck curve
      ..cubicTo(size.width * 0.88, 30, size.width * 0.98, 100, size.width * 0.95, 340) // Right draped mantle
      ..quadraticBezierTo(size.width * 0.5, 370, size.width * 0.05, 340) // Hem bottom
      ..cubicTo(size.width * 0.02, 100, size.width * 0.12, 30, size.width * 0.32, 20); // Left mantle

    // Cloak Drop Shadow
    canvas.drawShadow(path, Colors.black, 12, true);
    canvas.drawPath(path, cloakPaint);

    // Gold Trim & Royal Embroidery (Tibeb / Zereb)
    final goldTrimPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final collarGold = Path()
      ..moveTo(size.width * 0.32, 20)
      ..quadraticBezierTo(size.width * 0.5, 48, size.width * 0.68, 20);
    canvas.drawPath(collarGold, goldTrimPaint);

    // Center Front Opening Trims
    final centerGoldLeft = Path()
      ..moveTo(size.width * 0.44, 46)
      ..lineTo(size.width * 0.44, size.height * 0.92);
    final centerGoldRight = Path()
      ..moveTo(size.width * 0.56, 46)
      ..lineTo(size.width * 0.56, size.height * 0.92);

    final thinGoldPaint = Paint()
      ..color = const Color(0xFFE5A93C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(centerGoldLeft, thinGoldPaint);
    canvas.drawPath(centerGoldRight, thinGoldPaint);

    // Ceremonial Shoulder Epaulets & Cross Filigree
    final epauletPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.22, 60), 12, epauletPaint);
    canvas.drawCircle(Offset(size.width * 0.78, 60), 12, epauletPaint);

    // Ethiopian Cross Emblem at chest closure
    final crossPaint = Paint()
      ..color = const Color(0xFFFFF2A1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final centerX = size.width * 0.5;
    const centerY = 90.0;
    canvas.drawLine(Offset(centerX, centerY - 14), Offset(centerX, centerY + 14), crossPaint);
    canvas.drawLine(Offset(centerX - 12, centerY), Offset(centerX + 12, centerY), crossPaint);
    canvas.drawCircle(Offset(centerX, centerY), 6.0, epauletPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Habesha Kemis (የሀበሻ ቀሚስ)
/// Hand-spun pure white Shemma dress with vibrant woven Tibeb borders
class _HabeshaKemisGraphic extends StatelessWidget {
  const _HabeshaKemisGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 380),
      painter: _HabeshaKemisPainter(),
    );
  }
}

class _HabeshaKemisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dress fabric (Cotton white Shemma with soft gradients)
    final dressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFAFAFA), Color(0xFFEEEEEE)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dressPath = Path()
      ..moveTo(size.width * 0.35, 30) // Left neck
      ..quadraticBezierTo(size.width * 0.5, 60, size.width * 0.65, 30) // Neck
      ..lineTo(size.width * 0.88, 50) // Right shoulder
      ..lineTo(size.width * 0.94, 350) // Right skirt
      ..quadraticBezierTo(size.width * 0.5, 375, size.width * 0.06, 350) // Bottom hem
      ..lineTo(size.width * 0.12, 50) // Left shoulder
      ..close();

    canvas.drawShadow(dressPath, Colors.black38, 8, true);
    canvas.drawPath(dressPath, dressPaint);

    // Multi-color Traditional Tibeb Border at Neck & Chest
    final tibebColors = [
      const Color(0xFF1B5E20), // Ethiopian Green
      const Color(0xFFFDD835), // Gold Yellow
      const Color(0xFFC62828), // Crimson Red
      const Color(0xFF1565C0), // Royal Blue
    ];

    double currentY = 70.0;
    for (int i = 0; i < tibebColors.length; i++) {
      final borderPaint = Paint()
        ..color = tibebColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;

      canvas.drawLine(
        Offset(size.width * 0.40, currentY),
        Offset(size.width * 0.60, currentY),
        borderPaint,
      );
      currentY += 6;
    }

    // Wide Hem Tibeb Band
    final hemPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F9D58), Color(0xFFF4B400), Color(0xFFDB4437)],
      ).createShader(Rect.fromLTWH(0, 310, size.width, 30))
      ..style = PaintingStyle.fill;

    final hemBand = Rect.fromLTWH(size.width * 0.08, 315, size.width * 0.84, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(hemBand, const Radius.circular(4)), hemPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Oromo Traditional Attire (Wannyo & Kallacha)
class _OromoAttireGraphic extends StatelessWidget {
  const _OromoAttireGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 380),
      painter: _OromoAttirePainter(),
    );
  }
}

class _OromoAttirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ceremonial Red, Black and White traditional Oromo sash & vest
    final vestPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    final vestPath = Path()
      ..moveTo(size.width * 0.30, 20)
      ..quadraticBezierTo(size.width * 0.5, 70, size.width * 0.70, 20)
      ..lineTo(size.width * 0.90, 60)
      ..lineTo(size.width * 0.88, 330)
      ..lineTo(size.width * 0.12, 330)
      ..lineTo(size.width * 0.10, 60)
      ..close();

    canvas.drawShadow(vestPath, Colors.black45, 10, true);
    canvas.drawPath(vestPath, vestPaint);

    // Diagonal Ceremonial Red & White Sash
    final sashPaint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;

    final sashPath = Path()
      ..moveTo(size.width * 0.25, 30)
      ..lineTo(size.width * 0.45, 30)
      ..lineTo(size.width * 0.85, 330)
      ..lineTo(size.width * 0.65, 330)
      ..close();

    canvas.drawPath(sashPath, sashPaint);

    // White accent border
    final whiteLine = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawLine(Offset(size.width * 0.25, 30), Offset(size.width * 0.65, 330), whiteLine);
    canvas.drawLine(Offset(size.width * 0.45, 30), Offset(size.width * 0.85, 330), whiteLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Netela / Gabi Ceremonial White Shawl
class _NetelaShawlGraphic extends StatelessWidget {
  const _NetelaShawlGraphic();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(320, 380),
      painter: _NetelaShawlPainter(),
    );
  }
}

class _NetelaShawlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Flowing sheer white shawl draped across shoulders
    final shawlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final shawlPath = Path()
      ..moveTo(size.width * 0.05, 90)
      ..quadraticBezierTo(size.width * 0.5, 20, size.width * 0.95, 90)
      ..quadraticBezierTo(size.width * 0.98, 220, size.width * 0.85, 300)
      ..quadraticBezierTo(size.width * 0.5, 340, size.width * 0.15, 300)
      ..quadraticBezierTo(size.width * 0.02, 220, size.width * 0.05, 90);

    canvas.drawShadow(shawlPath, Colors.black26, 8, true);
    canvas.drawPath(shawlPath, shawlPaint);

    // Gold & green embroidered border edges
    final goldEdge = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawPath(shawlPath, goldEdge);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
