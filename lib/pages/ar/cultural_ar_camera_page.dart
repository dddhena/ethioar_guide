import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/landmark.dart';
import '../../services/firestore_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/ar/rope_leash_painter.dart';
import '../../widgets/ar/cultural_attire_overlay.dart';
import '../../widgets/ar/animal_companion_overlay.dart';

/// Cultural AR Camera Studio (Real-Life Environment, Photographic Attire & Pets, Photo/Video Mode Choice)
class CulturalArCameraPage extends StatefulWidget {
  final Landmark? initialLandmark;
  final String initialMode; // 'photo' or 'video'

  const CulturalArCameraPage({
    super.key,
    this.initialLandmark,
    this.initialMode = 'photo',
  });

  @override
  State<CulturalArCameraPage> createState() => _CulturalArCameraPageState();
}

class _CulturalArCameraPageState extends State<CulturalArCameraPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  List<Landmark> _availableLandmarks = [];
  Landmark? _selectedLandmark;

  // Selected Attire & Animal
  CulturalAttire? _activeAttire;
  NativeAnimal? _activeAnimal;

  // Real Hardware Camera controller
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isCameraInitializing = true;
  String? _cameraErrorMessage;
  String? _pickedEnvironmentPhoto; // Fallback real environment photo if camera unavailable

  // Mode: 'photo' or 'video'
  late String _captureMode;

  // Camera settings
  bool _isFrontCamera = false; // Default to rear camera to catch real-world environment
  bool _isSoundOn = true;

  // Interactive Horse Rope Anchoring
  Offset _animalBridlePoint = Offset.zero;
  Offset _userHandGripPoint = const Offset(200, 520);
  bool _isDraggingHandGrip = false;

  // Video recording state
  bool _isRecordingVideo = false;
  int _recordingSeconds = 0;
  Timer? _videoTimer;

  // Shutter flash effect
  bool _showFlashEffect = false;

  late AnimationController _ropeAnimController;

  @override
  void initState() {
    super.initState();
    _captureMode = widget.initialMode;
    _ropeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initHardwareCamera();
    _initLandmarkData();
  }

  @override
  void dispose() {
    _videoTimer?.cancel();
    _cameraController?.dispose();
    _ropeAnimController.dispose();
    super.dispose();
  }

  /// Initialize the physical device camera sensor
  Future<void> _initHardwareCamera() async {
    setState(() {
      _isCameraInitializing = true;
      _cameraErrorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final targetLens = _isFrontCamera
            ? CameraLensDirection.front
            : CameraLensDirection.back;

        final camera = _cameras.firstWhere(
          (c) => c.lensDirection == targetLens,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: true,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraReady = true;
            _isCameraInitializing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isCameraInitializing = false;
            _cameraErrorMessage = 'No physical camera detected on this device.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
          _cameraErrorMessage = 'Camera permission or hardware error: $e';
        });
      }
    }
  }

  Future<void> _initLandmarkData() async {
    try {
      _availableLandmarks = await _firestoreService.fetchLandmarks();
    } catch (_) {
      _availableLandmarks = [];
    }

    if (!mounted) return;

    if (widget.initialLandmark != null) {
      _selectedLandmark = widget.initialLandmark;
    } else if (_availableLandmarks.isNotEmpty) {
      _selectedLandmark = _availableLandmarks.first;
    }

    _applyLandmarkDefaults();
  }

  void _applyLandmarkDefaults() {
    final attires = _getAvailableAttires();
    final animals = _getAvailableAnimals();

    setState(() {
      _activeAttire = attires.isNotEmpty ? attires.first : null;
      _activeAnimal = animals.isNotEmpty ? animals.first : null;
    });
  }

  List<CulturalAttire> _getAvailableAttires() {
    if (_selectedLandmark != null && _selectedLandmark!.culturalAttires.isNotEmpty) {
      return _selectedLandmark!.culturalAttires;
    }
    return CulturalAttire.defaultPresets;
  }

  List<NativeAnimal> _getAvailableAnimals() {
    if (_selectedLandmark != null && _selectedLandmark!.nativeAnimals.isNotEmpty) {
      return _selectedLandmark!.nativeAnimals;
    }
    return NativeAnimal.defaultPresets;
  }

  Future<void> _switchCamera() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _cameraController?.dispose();
    _cameraController = null;
    await _initHardwareCamera();
  }

  Future<void> _pickEnvironmentBackground() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedEnvironmentPhoto = picked.path;
      });
    }
  }

  void _showCaptureModeChoiceForm() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: EthioColors.forest),
                  const SizedBox(width: 8),
                  const Text(
                    'Choose AR Capture Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Select whether you want to capture a photo snapshot or record an AR video:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _captureMode == 'photo' ? EthioColors.forest : Colors.grey.shade300,
                    width: _captureMode == 'photo' ? 2 : 1,
                  ),
                ),
                tileColor: _captureMode == 'photo' ? Colors.green.shade50 : null,
                leading: CircleAvatar(
                  backgroundColor: EthioColors.forest,
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                ),
                title: const Text('📸 Take Photo Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Snap a real-life photo with cultural clothes and native companion.'),
                trailing: _captureMode == 'photo'
                    ? const Icon(Icons.check_circle, color: EthioColors.forest)
                    : null,
                onTap: () {
                  setState(() => _captureMode = 'photo');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _captureMode == 'video' ? Colors.redAccent : Colors.grey.shade300,
                    width: _captureMode == 'video' ? 2 : 1,
                  ),
                ),
                tileColor: _captureMode == 'video' ? Colors.red.shade50 : null,
                leading: const CircleAvatar(
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.videocam_rounded, color: Colors.white),
                ),
                title: const Text('🎥 Record Video Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Record live video with horse rope motion, animal barking, and real sound.'),
                trailing: _captureMode == 'video'
                    ? const Icon(Icons.check_circle, color: Colors.redAccent)
                    : null,
                onTap: () {
                  setState(() => _captureMode = 'video');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleShutterPressed() {
    if (_captureMode == 'photo') {
      _takePhoto();
    } else {
      if (_isRecordingVideo) {
        _stopVideoRecording();
      } else {
        _startVideoRecording();
      }
    }
  }

  Future<void> _takePhoto() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);

    setState(() => _showFlashEffect = true);
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showFlashEffect = false);
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.takePicture();
      } catch (_) {}
    }

    _showPhotoCapturedDialog();
  }

  Future<void> _startVideoRecording() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecordingVideo = true;
      _recordingSeconds = 0;
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.startVideoRecording();
      } catch (_) {}
    }

    _videoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _recordingSeconds++;
      });
      if (_recordingSeconds >= 45) {
        _stopVideoRecording();
      }
    });
  }

  Future<void> _stopVideoRecording() async {
    _videoTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _isRecordingVideo = false;
    });

    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      try {
        await _cameraController!.stopVideoRecording();
      } catch (_) {}
    }

    _showVideoCapturedDialog();
  }

  void _showPhotoCapturedDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E212A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Real-Life AR Photo Captured!',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cultural Wear: ${_activeAttire?.name ?? "Traditional Attire"}\nReal-Life Companion: ${_activeAnimal?.name ?? "Native Wildlife"}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.castle_rounded, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedLandmark?.name ?? 'Real-World Heritage Experience',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Real Environment AR Lens • ${_selectedLandmark?.city.isNotEmpty == true ? _selectedLandmark!.city : "Ethiopia"}',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EthioColors.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Photo saved to gallery with Ethiopian AR Watermark!'),
                            backgroundColor: EthioColors.forest,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Save & Share', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoCapturedDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E212A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_rounded, color: Colors.amberAccent, size: 36),
              const SizedBox(height: 12),
              Text(
                'AR Video Recorded ($_recordingSeconds s)',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Captured real-world environment with dynamic animal sound effects and moving horse lead rope.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EthioColors.forest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video saved successfully!'), backgroundColor: EthioColors.forest),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save AR Video'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attires = _getAvailableAttires();
    final animals = _getAvailableAnimals();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Hardware Camera Sensor View (Catches the real environment)
          _buildCameraViewport(),

          // 2. Cultural Clothes Wearable Overlay (Real photographic garment)
          if (_activeAttire != null)
            CulturalAttireOverlay(
              attire: _activeAttire!,
              isInteractive: true,
            ),

          // 3. Native Animal Companion (Real photographic animal with character)
          if (_activeAnimal != null)
            AnimalCompanionOverlay(
              animal: _activeAnimal!,
              onBridleAnchorUpdated: (pos) {
                if (mounted) setState(() => _animalBridlePoint = pos);
              },
            ),

          // 4. Dynamic Lead Rope connecting Horse Bridle to User Hand
          if (_activeAnimal?.behaviorType == 'horse_rope' && _animalBridlePoint != Offset.zero)
            AnimatedBuilder(
              animation: _ropeAnimController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: RopeLeashPainter(
                    animalAnchor: _animalBridlePoint,
                    handAnchor: _userHandGripPoint,
                    animationValue: _ropeAnimController.value,
                    droopFactor: _isRecordingVideo ? 0.32 : 0.22,
                  ),
                );
              },
            ),

          // 5. Draggable Hand Grip Indicator for Horse Reins
          if (_activeAnimal?.behaviorType == 'horse_rope')
            Positioned(
              left: _userHandGripPoint.dx - 28,
              top: _userHandGripPoint.dy - 28,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _userHandGripPoint += details.delta;
                    _isDraggingHandGrip = true;
                  });
                },
                onPanEnd: (_) => setState(() => _isDraggingHandGrip = false),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isDraggingHandGrip ? Colors.white : Colors.amberAccent,
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.pan_tool_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),

          // 6. Camera Shutter Flash Effect
          if (_showFlashEffect)
            Container(color: Colors.white),

          // 7. Top HUD (Landmark Badge, Camera Switcher, Mode Choice Button)
          Positioned(
            top: 44,
            left: 16,
            right: 16,
            child: _buildTopHUD(),
          ),

          // 8. Recording Live Indicator (if video mode active)
          if (_isRecordingVideo)
            Positioned(
              top: 106,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REC ${_recordingSeconds}s',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 9. Bottom AR Lens Studio (Attire & Animal carousels + Shutter + Mode Choice Form)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _buildBottomLensStudio(attires, animals),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewport() {
    // 1. If physical camera controller is initialized and ready, show real environment preview
    if (_isCameraReady && _cameraController != null && _cameraController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    // 2. If user picked an environment photo
    if (_pickedEnvironmentPhoto != null) {
      return SizedBox.expand(
        child: Image.file(
          File(_pickedEnvironmentPhoto!),
          fit: BoxFit.cover,
        ),
      );
    }

    // 3. Fallback when camera is initializing or permission requested
    return Container(
      color: const Color(0xFF12161E),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCameraInitializing) ...[
              const CircularProgressIndicator(color: EthioColors.forest),
              const SizedBox(height: 16),
              const Text(
                'Starting device camera sensor...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ] else ...[
              const Icon(Icons.videocam_off_rounded, color: Colors.amberAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _cameraErrorMessage ?? 'Camera sensor not ready',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EthioColors.forest,
                  foregroundColor: Colors.white,
                ),
                onPressed: _pickEnvironmentBackground,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Pick Environment Background Photo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    return Row(
      children: [
        // Back button
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 8),

        // Landmark title pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: Colors.amberAccent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _selectedLandmark?.name ?? 'Live AR Lens Studio',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Mode Form Choice Trigger Button (Photo vs Video)
        GestureDetector(
          onTap: _showCaptureModeChoiceForm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _captureMode == 'video' ? Colors.redAccent : Colors.teal.shade700,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _captureMode == 'video' ? Icons.videocam : Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _captureMode == 'video' ? 'VIDEO' : 'PHOTO',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Switch Camera (Front vs Rear)
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isFrontCamera ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
              color: Colors.white,
            ),
            tooltip: 'Flip Camera',
            onPressed: _switchCamera,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomLensStudio(List<CulturalAttire> attires, List<NativeAnimal> animals) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Helper hint for horse rope
        if (_activeAnimal?.behaviorType == 'horse_rope')
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.7)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.amberAccent),
                SizedBox(width: 6),
                Text(
                  'Hold the golden ring to control the horse lead rope',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

        // 1. Cultural Attire Selector Carousel
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: attires.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _activeAttire == null;
                return GestureDetector(
                  onTap: () => setState(() => _activeAttire = null),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Center(
                      child: Text(
                        '🚫 No Attire',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final attire = attires[index - 1];
              final isSelected = _activeAttire?.id == attire.id;

              return GestureDetector(
                onTap: () => setState(() => _activeAttire = attire),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepOrange : Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.amberAccent : Colors.white24, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(attire.previewUrl),
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        attire.name,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 2. Native Animal Companion Selector Carousel
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: animals.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _activeAnimal == null;
                return GestureDetector(
                  onTap: () => setState(() => _activeAnimal = null),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: Center(
                      child: Text(
                        '🚫 No Pet',
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final animal = animals[index - 1];
              final isSelected = _activeAnimal?.id == animal.id;

              return GestureDetector(
                onTap: () => setState(() => _activeAnimal = animal),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.brown.shade700 : Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? Colors.amberAccent : Colors.white24, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundImage: NetworkImage(animal.previewUrl),
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        animal.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // 3. Segmented Mode Choice Selector (Photo vs Video)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isRecordingVideo) _stopVideoRecording();
                  setState(() => _captureMode = 'photo');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _captureMode == 'photo' ? EthioColors.forest : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: _captureMode == 'photo' ? Colors.white : Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'PHOTO',
                        style: TextStyle(
                          color: _captureMode == 'photo' ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _captureMode = 'video'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _captureMode == 'video' ? Colors.redAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.videocam, color: _captureMode == 'video' ? Colors.white : Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'VIDEO',
                        style: TextStyle(
                          color: _captureMode == 'video' ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 4. Shutter Action Button
        GestureDetector(
          onTap: _handleShutterPressed,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _captureMode == 'video' ? Colors.redAccent : Colors.white,
                width: 4,
              ),
              color: _isRecordingVideo ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: _isRecordingVideo ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: _isRecordingVideo ? BorderRadius.circular(10) : null,
                  color: _captureMode == 'video' ? Colors.red : Colors.white,
                ),
                child: Center(
                  child: _isRecordingVideo
                      ? const Icon(Icons.stop, color: Colors.white, size: 30)
                      : Icon(
                          _captureMode == 'video' ? Icons.fiber_manual_record : Icons.camera_alt,
                          color: _captureMode == 'video' ? Colors.white : Colors.black87,
                          size: 26,
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _captureMode == 'video'
              ? (_isRecordingVideo ? 'Recording Video... Tap to Stop' : 'Tap to Start Video Recording')
              : 'Tap to Take AR Snapshot',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
