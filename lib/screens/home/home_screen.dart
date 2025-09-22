import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/core/constants.dart';
import 'package:detection_game/screens/home/home_controller.dart';
import 'package:detection_game/services/consent_manager.dart';
import 'package:detection_game/services/permission_manager.dart';
import 'package:detection_game/widgets/data_transmission_dialog.dart';
import 'package:detection_game/widgets/recording_permission_dialog.dart';

class HomeScreen extends ConsumerWidget {
  final CameraDescription camera;
  const HomeScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vision = ref.watch(visionServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('ゲーム開始'),
          onPressed: () async {
            final success = await _requestAllPermissions(context);
            if (success && context.mounted) {
              Navigator.of(context).pushNamed(
                AppRoutes.gamePlay,
                arguments: {'camera': camera, 'vision': vision},
              );
            }
          },
        ),
      ),
    );
  }

  Future<bool> _requestAllPermissions(BuildContext context) async {
    final hasDataConsent = await ConsentManager.hasGivenDataTransmissionConsent();
    if (!hasDataConsent) {
      if (!context.mounted) return false;
      final dataConfirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => DataTransmissionDialog(
          onConfirm: () => Navigator.of(dialogCtx).pop(true),
          onCancel: () => Navigator.of(dialogCtx).pop(false),
        ),
      );
      if (dataConfirmed != true) return false;
      await ConsentManager.giveDataTransmissionConsent();
    }

    final hasCameraPermission = await PermissionManager.hasCameraPermission();
    if (!hasCameraPermission) {
      if (!context.mounted) return false;
      final cameraConfirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('カメラ許可の確認'),
          content: const Text('ゲームで写真を撮影するため、カメラへのアクセス許可が必要です。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('許可する'),
            ),
          ],
        ),
      );
      if (cameraConfirmed != true) return false;
      
      final granted = await PermissionManager.requestCameraPermission();
      if (!granted) {
        if (!context.mounted) return false;
        _showPermissionDeniedDialog(context, 'カメラ');
        return false;
      }
    }

    final hasMicPermission = await PermissionManager.hasMicrophonePermission();
    if (!hasMicPermission) {
      if (!context.mounted) return false;
      final micConfirmed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => RecordingPermissionDialog(
          onConfirm: () => Navigator.of(dialogCtx).pop(true),
          onCancel: () => Navigator.of(dialogCtx).pop(false),
        ),
      );
      if (micConfirmed != true) return false;
      
      final granted = await PermissionManager.requestMicrophonePermission();
      if (!granted) {
        if (!context.mounted) return false;
        _showPermissionDeniedDialog(context, 'マイク');
        return false;
      }
    }

    return true;
  }

  void _showPermissionDeniedDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('許可が必要です'),
        content: Text('$permissionNameの許可が拒否されました。設定から許可を有効にしてください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              PermissionManager.openAppSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }
}
