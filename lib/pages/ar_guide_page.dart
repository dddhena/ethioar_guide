import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../models/landmark.dart';
import 'landmarks_page.dart';

class ARGuidePage extends StatefulWidget {
  const ARGuidePage({Key? key}) : super(key: key);

  @override
  State<ARGuidePage> createState() => _ARGuidePageState();
}

class _ARGuidePageState extends State<ARGuidePage> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;
  late ARLocationManager arLocationManager;
  final FirestoreService _fs = FirestoreService();
  bool _loading = true;
  List<Landmark> _landmarks = [];

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    setState(() => _loading = true);
    _landmarks = await _fs.fetchLandmarks();
    setState(() => _loading = false);
  }

  void onARViewCreated(ARSessionManager sessionManager, ARObjectManager objectManager, ARAnchorManager anchorManager, ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;
    arLocationManager = locationManager;

    arSessionManager.onInitialize(showFeaturePoints: false, showPlanes: true);
    arObjectManager.onInitialize();

    // Map node names to landmarks for tap handling
    final Map<String, Landmark> nodeLandmark = {};

    // Add simple markers for each landmark — placed in front of the camera with spaced Z positions.
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
      arObjectManager.addNode(node);
      nodeLandmark[lm.id] = lm;
    }

    // When tapped, show a snackbar with info
    arObjectManager.onNodeTap = (nodes) {
      if (nodes.isEmpty) return;
      final tapped = nodes.first;
      final lm = nodeLandmark[tapped.name];
      if (lm != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lm.name}: ${lm.description}')));
      }
    };
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Tourist Guide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'View landmarks',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LandmarksPage())),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ARView(
                  onARViewCreated: onARViewCreated,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white70,
                    child: Text('Landmarks: ${_landmarks.length}'),
                  ),
                )
              ],
            ),
    );
  }
}
