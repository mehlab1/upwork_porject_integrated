// Conditional export: use real implementation on mobile, stub on web
export 'fcm_service_stub.dart'
    if (dart.library.io) 'fcm_service_impl.dart';
