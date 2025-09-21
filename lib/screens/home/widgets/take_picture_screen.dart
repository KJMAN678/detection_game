import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:detection_game/services/permission_manager.dart';
import 'package:detection_game/vision/vision_service.dart';
import 'package:detection_game/screens/detail/detail_model.dart';
import 'package:detection_game/core/constants.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
    required this.vision,
    this.captureEnabled = true,
    this.onEarned,
    this.externalTotalPoints,
    this.showExternalTotalAsTotal = false,
    this.usedLabels,
    this.onCommittedLabels,
  });

  final CameraDescription camera;
  final VisionService vision;

  final bool captureEnabled;
  final void Function(int earned)? onEarned;
  final int? externalTotalPoints;
  final bool showExternalTotalAsTotal;

  final Set<String>? usedLabels;
  final void Function(List<String> labels)? onCommittedLabels;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final hasPermission = await PermissionManager.hasCameraPermission();

    if (!hasPermission) {
      final granted = await PermissionManager.requestCameraPermission();
      if (!granted) {
        throw Exception('カメラ権限が必要です');
      }
    }

    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze(BuildContext context) async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!context.mounted) return;

      final result = await Navigator.of(context).pushNamed<EarnResult>(
        AppRoutes.displayPicture,
        arguments: {
          'imagePath': image.path,
          'vision': widget.vision,
          'usedLabels': widget.usedLabels,
        },
      );
      if (!context.mounted) return;

      if (result != null && result.earned > 0) {
        if (widget.onEarned != null) {
          widget.onEarned!(result.earned);
        } else {
          setState(() {
            _totalPoints += result.earned;
          });
        }
        if (widget.onCommittedLabels != null) {
          widget.onCommittedLabels!(result.labels);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラー: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller)),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'total ${widget.showExternalTotalAsTotal && widget.externalTotalPoints != null ? widget.externalTotalPoints! : _totalPoints} points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.captureEnabled
            ? () => _captureAndAnalyze(context)
            : null,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
