import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }
  
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  static Future<PermissionStatus> getCameraPermissionStatus() async {
    return await Permission.camera.status;
  }
  
  static Future<bool> shouldShowCameraPermissionRationale() async {
    final status = await Permission.camera.status;
    return status.isDenied;
  }
  
  static Future<bool> isCameraPermissionPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }
  
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
