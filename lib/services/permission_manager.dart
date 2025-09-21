import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

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
    await permission_handler.openAppSettings();
  }

  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<PermissionStatus> getMicrophonePermissionStatus() async {
    return await Permission.microphone.status;
  }

  static Future<bool> shouldShowMicrophonePermissionRationale() async {
    final status = await Permission.microphone.status;
    return status.isDenied;
  }

  static Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }
}
