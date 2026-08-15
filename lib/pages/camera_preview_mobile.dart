import 'package:flutter/material.dart';
import 'ar_guide.dart';

class CameraPreviewPage extends StatelessWidget {
  const CameraPreviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // On mobile we immediately navigate to the AR implementation
    return const ARGuidePage();
  }
}
