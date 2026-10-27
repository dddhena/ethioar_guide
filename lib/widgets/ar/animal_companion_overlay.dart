import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/landmark.dart';

/// Animal Companion Overlay
/// Renders the native animal beside the user with authentic real-life behaviors:
/// - Horse with halter bridle anchor for interactive rope leash & gentle trot/breath
/// - Dog that barks proactively at camera with visual & audio feedback
/// - Endemic highland wildlife (Walia Ibex / Baboon) standing majestically
class AnimalCompanionOverlay extends StatefulWidget {
  final NativeAnimal animal;
  final Function(Offset bridleAnchor)? onBridleAnchorUpdated;
  final bool isInteractive;

  const AnimalCompanionOverlay({
    super.key,
    required this.animal,
    this.onBridleAnchorUpdated,
    this.isInteractive = true,
  });

  @override
  State<AnimalCompanionOverlay> createState() => _AnimalCompanionOverlayState();
}

class _AnimalCompanionOverlayState extends State<AnimalCompanionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _motionController;
  Timer? _dogBarkTimer;

  // Interaction position & scaling
  Offset _position = const Offset(40, 160);
  double _scale = 1.0;
  double _baseScale = 1.0;

  // Dog alert / barking state
  bool _isBarking = false;
  int _barkCount = 0;

  final GlobalKey _bridleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _motionController.addListener(_reportBridlePosition);

    if (widget.animal.behaviorType == 'barking_dog') {
      _startPeriodicDogBarking();
    }
  }

  @override
  void didUpdateWidget(covariant AnimalCompanionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animal.id != widget.animal.id) {
      _dogBarkTimer?.cancel();
      if (widget.animal.behaviorType == 'barking_dog') {
        _startPeriodicDogBarking();
      }
      // Re-anchor when switching animals
      setState(() {
        _position = widget.animal.behaviorType == 'horse_rope'
            ? const Offset(20, 120)
            : const Offset(40, 220);
        _scale = widget.animal.defaultScale;
      });
    }
  }

  @override
  void dispose() {
    _dogBarkTimer?.cancel();
    _motionController.dispose();
    super.dispose();
  }

  void _startPeriodicDogBarking() {
    _dogBarkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _triggerBark();
    });
  }

  void _triggerBark() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isBarking = true;
      _barkCount++;
    });

    Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _isBarking = false);
    });
  }

  void _reportBridlePosition() {
    if (widget.onBridleAnchorUpdated == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _bridleKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(
            Offset(renderBox.size.width / 2, renderBox.size.height / 2),
          );
          widget.onBridleAnchorUpdated!(position);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: (screenSize.width * 0.5 - 120) + _position.dx,
      top: (screenSize.height * 0.4) + _position.dy,
      child: GestureDetector(
        onTap: () {
          if (widget.animal.behaviorType == 'barking_dog') {
            _triggerBark();
          } else {
            HapticFeedback.lightImpact();
          }
        },
        onScaleStart: widget.isInteractive
            ? (details) {
                _baseScale = _scale;
              }
            : null,
        onScaleUpdate: widget.isInteractive
            ? (details) {
                setState(() {
                  _scale = (_baseScale * details.scale).clamp(0.5, 2.0);
                  _position += details.focalPointDelta;
                });
                _reportBridlePosition();
              }
            : null,
        child: AnimatedBuilder(
          animation: _motionController,
          builder: (context, child) {
            final breathOffset = math.sin(_motionController.value * math.pi) * 4.0;

            return Transform.translate(
              offset: Offset(0, breathOffset),
              child: Transform.scale(
                scale: _scale,
                child: SizedBox(
                  width: 240,
                  height: 280,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Visual animal character
                      _buildAnimalGraphic(widget.animal),

                      // Reactive Dog Bark Speech bubble / sound indicator
                      if (widget.animal.behaviorType == 'barking_dog' && _isBarking)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volume_up_rounded, size: 14, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  'WOOF! 🐕 (Guarding)',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Halter / Bridle anchor key target for RopeLeashPainter
                      if (widget.animal.behaviorType == 'horse_rope')
                        Positioned(
                          top: 75,
                          left: 60,
                          child: Container(
                            key: _bridleKey,
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimalGraphic(NativeAnimal animal) {
    final photoUrl = animal.previewUrl.isNotEmpty && animal.previewUrl.startsWith('http')
        ? animal.previewUrl
        : (animal.modelUrl.isNotEmpty && animal.modelUrl.startsWith('http') ? animal.modelUrl : '');

    if (photoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          photoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackVector(animal),
        ),
      );
    }
    return _buildFallbackVector(animal);
  }

  Widget _buildFallbackVector(NativeAnimal animal) {
    switch (animal.behaviorType) {
      case 'horse_rope':
        return _AbyssinianHorseGraphic(animationVal: _motionController.value);
      case 'barking_dog':
        return _ShepherdDogGraphic(isBarking: _isBarking, animationVal: _motionController.value);
      case 'ambient_wildlife':
      default:
        return _MountainWildlifeGraphic(name: animal.name);
    }
  }
}

/// 1. Abyssinian Horse Graphic
/// Dignified Ethiopian war horse with ceremonial brass bridle and dark mane
class _AbyssinianHorseGraphic extends StatelessWidget {
  final double animationVal;

  const _AbyssinianHorseGraphic({required this.animationVal});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(240, 280),
      painter: _AbyssinianHorsePainter(headNod: math.sin(animationVal * math.pi) * 3),
    );
  }
}

class _AbyssinianHorsePainter extends CustomPainter {
  final double headNod;

  _AbyssinianHorsePainter({required this.headNod});

  @override
  void paint(Canvas canvas, Size size) {
    // Horse coat: Warm Chestnut Bay with realistic shading
    final coatPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6B3A24), Color(0xFF421C0E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Head, Neck & Powerful Crest
    final neckPath = Path()
      ..moveTo(size.width * 0.35, 70 + headNod) // Muzzle nose
      ..lineTo(size.width * 0.50, 40 + headNod) // Forehead
      ..lineTo(size.width * 0.58, 20 + headNod) // Ear base
      ..lineTo(size.width * 0.62, 5 + headNod)  // Ear tip
      ..lineTo(size.width * 0.66, 25 + headNod) // Ear back
      ..quadraticBezierTo(size.width * 0.90, 80, size.width * 0.95, 270) // Powerful muscular neck crest
      ..lineTo(size.width * 0.40, 270) // Shoulder chest base
      ..quadraticBezierTo(size.width * 0.42, 160, size.width * 0.28, 95 + headNod) // Throat & jaw
      ..close();

    // Drop shadow on ground/camera
    canvas.drawShadow(neckPath, Colors.black45, 12, true);
    canvas.drawPath(neckPath, coatPaint);

    // Dark flowing mane on crest
    final manePaint = Paint()
      ..color = const Color(0xFF1A0A05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    final manePath = Path()
      ..moveTo(size.width * 0.64, 30 + headNod)
      ..quadraticBezierTo(size.width * 0.88, 85, size.width * 0.94, 250);
    canvas.drawPath(manePath, manePaint);

    // Horse intelligent dark eye
    final eyePaint = Paint()..color = const Color(0xFF100804);
    canvas.drawCircle(Offset(size.width * 0.48, 55 + headNod), 5.5, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.49, 54 + headNod), 1.8, Paint()..color = Colors.white);

    // Ceremonial Leather Bridle / Halter Straps
    final bridlePaint = Paint()
      ..color = const Color(0xFFD4AF37) // Ceremonial Gold & Red Leather
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Noseband
    canvas.drawLine(
      Offset(size.width * 0.33, 72 + headNod),
      Offset(size.width * 0.38, 84 + headNod),
      bridlePaint,
    );

    // Browband & Cheekpiece to bit
    canvas.drawLine(
      Offset(size.width * 0.52, 45 + headNod),
      Offset(size.width * 0.35, 78 + headNod),
      bridlePaint,
    );

    // Bit / Halter Lead Ring where rope connects
    final brassRingPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.35, 78 + headNod), 6.0, brassRingPaint);
  }

  @override
  bool shouldRepaint(covariant _AbyssinianHorsePainter oldDelegate) =>
      oldDelegate.headNod != headNod;
}

/// 2. Ethiopian Shepherd Guard Dog Graphic
/// Alert guarding companion with barking animation & perked ears
class _ShepherdDogGraphic extends StatelessWidget {
  final bool isBarking;
  final double animationVal;

  const _ShepherdDogGraphic({required this.isBarking, required this.animationVal});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(240, 280),
      painter: _ShepherdDogPainter(isBarking: isBarking, breath: math.sin(animationVal * math.pi) * 2),
    );
  }
}

class _ShepherdDogPainter extends CustomPainter {
  final bool isBarking;
  final double breath;

  _ShepherdDogPainter({required this.isBarking, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    // Golden Tan Coat with dark muzzle
    final coatPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFC48B47), Color(0xFF8B5A2B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Alert seated / standing posture
    final bodyPath = Path()
      ..moveTo(size.width * 0.30, 80 + breath) // Muzzle
      ..lineTo(size.width * 0.50, 45 + breath) // Forehead
      ..lineTo(size.width * 0.55, 10 + breath) // Left perked ear
      ..lineTo(size.width * 0.65, 35 + breath)
      ..lineTo(size.width * 0.72, 12 + breath) // Right perked ear
      ..lineTo(size.width * 0.80, 40 + breath)
      ..quadraticBezierTo(size.width * 0.85, 120, size.width * 0.90, 260) // Back
      ..lineTo(size.width * 0.35, 260) // Paws
      ..quadraticBezierTo(size.width * 0.40, 160, size.width * 0.28, 105 + breath) // Chest & jaw
      ..close();

    canvas.drawShadow(bodyPath, Colors.black38, 10, true);
    canvas.drawPath(bodyPath, coatPaint);

    // Dark alert muzzle
    final muzzlePaint = Paint()..color = const Color(0xFF2A1B0E);
    final muzzleRect = Rect.fromCenter(
      center: Offset(size.width * 0.32, 85 + breath),
      width: 24,
      height: 18,
    );
    canvas.drawOval(muzzleRect, muzzlePaint);

    // Mouth: open during bark!
    if (isBarking) {
      final mouthOpenPaint = Paint()..color = const Color(0xFF6B1818);
      final tonguePaint = Paint()..color = const Color(0xFFE57373);
      final mouthRect = Rect.fromLTWH(size.width * 0.28, 92 + breath, 18, 14);
      canvas.drawRRect(RRect.fromRectAndRadius(mouthRect, const Radius.circular(4)), mouthOpenPaint);
      canvas.drawCircle(Offset(size.width * 0.34, 100 + breath), 4.0, tonguePaint);
    }

    // Loyal brown eyes
    final eyePaint = Paint()..color = const Color(0xFF1E130B);
    canvas.drawCircle(Offset(size.width * 0.48, 55 + breath), 4.5, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.49, 54 + breath), 1.5, Paint()..color = Colors.white);

    // Traditional red braided collar
    final collarPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.40, 108 + breath),
      Offset(size.width * 0.65, 115 + breath),
      collarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShepherdDogPainter oldDelegate) =>
      oldDelegate.isBarking != isBarking || oldDelegate.breath != breath;
}

/// 3. Mountain Wildlife Graphic (Walia Ibex / Gelada)
class _MountainWildlifeGraphic extends StatelessWidget {
  final String name;

  const _MountainWildlifeGraphic({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.amber.shade700, Colors.brown.shade900],
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.terrain_rounded, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent),
            ),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
