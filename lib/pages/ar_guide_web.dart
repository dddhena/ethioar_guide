import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../models/landmark.dart';
import 'map_picker.dart';
import 'landmarks_page.dart';

class ARGuidePage extends StatefulWidget {
  const ARGuidePage({Key? key}) : super(key: key);

  @override
  State<ARGuidePage> createState() => _ARGuidePageState();
}

class _ARGuidePageState extends State<ARGuidePage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Tourist Guide (Web)'),
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AR is not available in this browser build.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Here are the tourist landmarks from Firestore:'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _landmarks.length,
                      itemBuilder: (context, i) {
                        final lm = _landmarks[i];
                        return Card(
                          child: ListTile(
                            title: Text(lm.name),
                            subtitle: Text(lm.description),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${lm.latitude.toStringAsFixed(3)}, ${lm.longitude.toStringAsFixed(3)}'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.map),
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => MapPickerPage(
                                        initialPosition: LatLng(lm.latitude, lm.longitude),
                                        readOnly: true,
                                      ),
                                    ));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
