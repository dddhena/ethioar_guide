// Conditional export: choose platform-specific camera preview implementation
export 'camera_preview_mobile.dart'
    if (dart.library.html) 'camera_preview_web.dart';

// The exported file provides CameraPreviewPage widget in both cases.
