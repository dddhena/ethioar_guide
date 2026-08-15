import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/landmark.dart';
import 'map_picker.dart';
import 'dashboard_page.dart'; // for AddLandmarkPage

class LandmarksPage extends StatefulWidget {
  const LandmarksPage({Key? key}) : super(key: key);

  @override
  State<LandmarksPage> createState() => _LandmarksPageState();
}

class _LandmarksPageState extends State<LandmarksPage> {
  final FirestoreService _fs = FirestoreService();
  final AuthService _auth = AuthService();
  bool _loading = true;
  List<Landmark> _landmarks = [];
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _role = await _fs.getUserRole(uid);
    }
    _landmarks = await _fs.fetchLandmarks();
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this landmark?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (ok == true) {
      await _fs.deleteLandmark(id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Landmarks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
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
                          IconButton(
                            icon: const Icon(Icons.map),
                            tooltip: 'View on map',
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => MapPickerPage(
                                  initialPosition: LatLng(lm.latitude, lm.longitude),
                                  readOnly: true,
                                ),
                              ));
                            },
                          ),
                          if (_role == 'admin') ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: () async {
                                final res = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(builder: (_) => AddLandmarkPage(landmark: lm, id: lm.id)),
                                );
                                if (res == true) await _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                              onPressed: () => _delete(lm.id),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _role == 'admin'
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                final res = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddLandmarkPage()));
                if (res == true) await _load();
              },
            )
          : null,
    );
  }
}
