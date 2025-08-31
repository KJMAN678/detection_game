import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver_plus.dart';

import 'models/vision_result.dart';
import 'vision/client_direct_vision_adapter.dart';
import 'vision/vision_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  final apiKey = const String.fromEnvironment('VISION_API_KEY', defaultValue: '');
  final vision = ClientDirectVisionAdapter(apiKey: apiKey);

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        camera: firstCamera,
        vision: vision,
      ),
    ),
  );
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera, required this.vision});

  final CameraDescription camera;
  final VisionService vision;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
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

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            vision: widget.vision,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
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
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _captureAndAnalyze(context),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final VisionService vision;

  const DisplayPictureScreen({super.key, required this.imagePath, required this.vision});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  VisionResult _result = VisionResult.empty;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final sw = Stopwatch()..start();
      final res = await widget.vision.analyze(
        imageBytes: Uint8List.fromList(bytes),
        modes: const [VisionMode.objects, VisionMode.labels],
      );
      sw.stop();
      setState(() {
        _result = res;
      });
      // Simple log
      // ignore: avoid_print
      print('analyze took ${sw.elapsedMilliseconds} ms');
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final ok = await GallerySaver.saveImage(widget.imagePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok == true ? 'ギャラリーに保存しました' : '保存に失敗しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.file(File(widget.imagePath));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
        actions: [
          IconButton(
            onPressed: _saveToGallery,
            icon: const Icon(Icons.save_alt),
            tooltip: 'ギャラリーに保存',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: imageWidget),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          if (!_loading && _error == null)
            Positioned.fill(
              child: CustomPaint(
                painter: _OverlayPainter(result: _result),
              ),
            ),
          if (!_loading && _error == null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _result.labels
                      .map(
                        (l) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l.description,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final VisionResult result;

  _OverlayPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = (String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(color: Colors.yellow, fontSize: 14)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    };

    for (final o in result.objects) {
      final rect = Rect.fromLTWH(
        o.bbox.x * size.width,
        o.bbox.y * size.height,
        o.bbox.w * size.width,
        o.bbox.h * size.height,
      );
      canvas.drawRect(rect, boxPaint);

      final tp = textPainter(o.name);
      final offset = Offset(rect.left, rect.top - tp.height - 2);
      tp.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
