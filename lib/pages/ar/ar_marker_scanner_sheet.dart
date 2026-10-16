import 'package:flutter/material.dart';
import '../../models/heritage_3d_landmark.dart';
import '../../theme/ethio_theme.dart';
import 'heritage_3d_explorer_page.dart';

class ArMarkerScannerSheet extends StatefulWidget {
  const ArMarkerScannerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ArMarkerScannerSheet(),
    );
  }

  @override
  State<ArMarkerScannerSheet> createState() => _ArMarkerScannerSheetState();
}

class _ArMarkerScannerSheetState extends State<ArMarkerScannerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  bool _markerDetected = false;
  Heritage3DLandmark? _detectedLandmark;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate auto-detecting an authentic marker after 2.2 seconds
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _markerDetected = true;
          _detectedLandmark = Heritage3DLandmark.sampleHeritageModels.first; // Bete Giyorgis
        });
      }
    });
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _open3DModel(Heritage3DLandmark landmark) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Heritage3DExplorerPage(initialLandmark: landmark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF12141A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.document_scanner, color: Colors.amberAccent),
                const SizedBox(width: 10),
                const Text(
                  'AR Marker & Plaque Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera viewfinder background
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=800&q=80',
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.35),
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),

                        // Viewfinder reticle
                        Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _markerDetected ? Colors.greenAccent : Colors.amberAccent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                // Animated scan line
                                if (!_markerDetected)
                                  AnimatedBuilder(
                                    animation: _scanLineController,
                                    builder: (context, _) {
                                      return Positioned(
                                        top: _scanLineController.value * 236,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.amber.withValues(alpha: 0.1),
                                                Colors.amberAccent,
                                                Colors.amber.withValues(alpha: 0.1),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.amberAccent.withValues(alpha: 0.8),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top instructions banner
                Positioned(
                  top: 36,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _markerDetected ? Icons.check_circle : Icons.sensors,
                          color: _markerDetected ? Colors.greenAccent : Colors.amberAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _markerDetected
                              ? 'Heritage Marker Recognized!'
                              : 'Aim camera at museum plaque, ticket, or sign',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

                // Detected 3D Overlay Card
                if (_markerDetected && _detectedLandmark != null)
                  Positioned(
                    bottom: 36,
                    left: 36,
                    right: 36,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E222B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '3D MODEL MATCH',
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _detectedLandmark!.period,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _detectedLandmark!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _detectedLandmark!.amharicName,
                            style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _open3DModel(_detectedLandmark!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EthioColors.terracotta,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.view_in_ar, size: 18),
                              label: const Text(
                                'Launch 3D & AR Explorer',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
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
