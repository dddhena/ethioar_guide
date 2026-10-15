import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../services/firestore_service.dart';
import '../models/landmark.dart';

class ARGuidePage extends StatefulWidget {
  const ARGuidePage({super.key});

  @override
  State<ARGuidePage> createState() => _ARGuidePageState();
}

class _ARGuidePageState extends State<ARGuidePage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;
  final FirestoreService _fs = FirestoreService();
  bool _loading = true;
  bool _hasArError = false;
  String _errorMessage = '';
  List<Landmark> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  @override
  void dispose() {
    try {
      arSessionManager?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadLandmarks() async {
    setState(() => _loading = true);
    try {
      _landmarks = await _fs.fetchLandmarks();
    } catch (_) {
      _landmarks = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    try {
      arSessionManager?.onInitialize(showFeaturePoints: false, showPlanes: true);
      arObjectManager?.onInitialize();

      final Map<String, Landmark> nodeLandmark = {};

      for (var i = 0; i < _landmarks.length; i++) {
        final lm = _landmarks[i];
        final node = ARNode(
          type: NodeType.webGLB,
          uri: "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
          scale: vm.Vector3(0.2, 0.2, 0.2),
          position: vm.Vector3(0.0, 0.0, -1.5 - i * 1.5),
          rotation: vm.Vector4(1, 0, 0, 0),
          name: lm.id,
        );
        arObjectManager?.addNode(node);
        nodeLandmark[lm.id] = lm;
      }

      arObjectManager?.onNodeTap = (nodeNames) {
        if (nodeNames.isEmpty) return;
        final tappedName = nodeNames.first;
        final lm = nodeLandmark[tappedName];
        if (lm != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${lm.name}: ${lm.description}')),
          );
        }
      };
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasArError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Tourist Guide (Mobile)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasArError
              ? _buildArFallbackView()
              : Stack(
                  children: [
                    ARView(
                      onARViewCreated: onARViewCreated,
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Landmarks: ${_landmarks.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildArFallbackView() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.view_in_ar_rounded, size: 64, color: Colors.amberAccent),
          const SizedBox(height: 16),
          const Text(
            'AR Hardware Simulation Active',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage.isNotEmpty
                ? 'Device notice: $_errorMessage\n(Displaying simulated AR landmark feed)'
                : 'Google Play Services for AR (ARCore) is not available on this device.\nFalling back to simulated AR explorer.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _landmarks.length,
              itemBuilder: (ctx, idx) {
                final lm = _landmarks[idx];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amberAccent,
                      child: Icon(Icons.castle_rounded, color: Colors.black),
                    ),
                    title: Text(lm.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      lm.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
