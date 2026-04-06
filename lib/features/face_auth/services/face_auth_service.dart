export 'face_auth_service_base.dart';

// Conditional import: use mobile implementation on native platforms,
// web stub on web.
export 'face_auth_service_mobile.dart'
    if (dart.library.html) 'face_auth_service_web.dart';
