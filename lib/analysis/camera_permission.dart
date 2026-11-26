import 'package:permission_handler/permission_handler.dart' as handler;

/// Where the camera permission stands.
enum CameraPermissionStatus {
  granted,

  /// Not granted yet; the system dialog can still be shown.
  denied,

  /// Refused for good; only the system settings can grant it now.
  permanentlyDenied,
}

/// The Android camera permission. Screens depend on this interface so tests can answer it.
abstract interface class CameraPermission {
  Future<CameraPermissionStatus> status();

  /// Shows the system dialog and returns the user's answer.
  Future<CameraPermissionStatus> request();

  /// Opens the app's page in the system settings.
  Future<void> openSettings();
}

/// [CameraPermission] through the permission_handler plugin.
class PluginCameraPermission implements CameraPermission {
  const PluginCameraPermission();

  @override
  Future<CameraPermissionStatus> status() async => _map(await handler.Permission.camera.status);

  @override
  Future<CameraPermissionStatus> request() async => _map(await handler.Permission.camera.request());

  @override
  Future<void> openSettings() => handler.openAppSettings();

  static CameraPermissionStatus _map(handler.PermissionStatus status) => switch (status) {
        handler.PermissionStatus.granted || handler.PermissionStatus.limited => CameraPermissionStatus.granted,
        handler.PermissionStatus.permanentlyDenied ||
        handler.PermissionStatus.restricted =>
          CameraPermissionStatus.permanentlyDenied,
        _ => CameraPermissionStatus.denied,
      };
}
