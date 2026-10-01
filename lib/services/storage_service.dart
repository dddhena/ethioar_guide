import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  Future<String> uploadLandmarkImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final path = 'landmarks/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/$ext'),
    );
    return ref.getDownloadURL();
  }

  /// Uploads a tour guide profile photo to `guide_profiles/{userId}/profile.jpg`.
  Future<String> uploadGuideProfilePhoto(String userId, XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final safeExt = (ext == 'png' || ext == 'webp' || ext == 'jpeg') ? ext : 'jpg';
    final path = 'guide_profiles/$userId/profile.$safeExt';
    final ref = _storage.ref().child(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/$safeExt'),
    );
    return ref.getDownloadURL();
  }
}
