// Conditional export: re-export the platform-specific ARGuidePage implementation
export 'ar_guide_mobile.dart'
    if (dart.library.html) 'ar_guide_web.dart';

// The exported file provides ARGuidePage widget in both cases.
