import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:audioplayers/audioplayers.dart';

import 'models/vision_result.dart';
import 'vision/client_direct_vision_adapter.dart';
import 'vision/vision_service.dart';
import 'services/consent_manager.dart';
import 'services/permission_manager.dart';
import 'screens/privacy_consent_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/data_transmission_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
  );

  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: AppInitializer(camera: firstCamera),
    ),
  );
}

class AppInitializer extends StatefulWidget {
  final CameraDescription camera;
  
  const AppInitializer({super.key, required this.camera});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkConsentAndNavigate();
  }

  Future<void> _checkConsentAndNavigate() async {
    final hasConsent = await ConsentManager.hasGivenConsent();
    
    if (!mounted) return;
    
    if (hasConsent) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameStartScreen(camera: widget.camera),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PrivacyConsentScreen(
            camera: widget.camera,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class GameStartScreen extends StatefulWidget {
  final CameraDescription camera;
  const GameStartScreen({super.key, required this.camera});

  @override
  State<GameStartScreen> createState() => _GameStartScreenState();
}

class _GameStartScreenState extends State<GameStartScreen> {
  VisionService? _vision;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initVision();
  }

  Future<void> _initVision() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('callExternalApi');
      final res = await callable({});
      final apiKey = res.data['apiKey'];
      if (!mounted) return;
      setState(() {
        _vision = ClientDirectVisionAdapter(apiKey: apiKey);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const CircularProgressIndicator()
        : (_error != null
            ? Text('初期化エラー: $_error')
            : ElevatedButton(
                onPressed: _vision == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GamePlayScreen(
                              camera: widget.camera,
                              vision: _vision!,
                            ),
                          ),
                        );
                      },
                child: const Text('START'),
              ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(child: body),
    );
  }
}

class EarnResult {
  final int earned;
  final List<String> labels;
  EarnResult({required this.earned, required this.labels});
}



class GamePlayScreen extends StatefulWidget {
  final CameraDescription camera;
  final VisionService vision;
  const GamePlayScreen({super.key, required this.camera, required this.vision});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}


class _GamePlayScreenState extends State<GamePlayScreen> {
  final _player = AudioPlayer();
  int _sessionPoints = 0;
  bool _timeUp = false;
  Timer? _timer;
  int _remaining = 10;
  final Set<String> _usedLabels = {};

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/MusMus-BGM-125.mp3'));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _timeUp = true;
          _remaining = 0;
          t.cancel();
        }
      });
      if (_timeUp) {
        await _endGame();
      }
    });
  }

  Future<void> _endGame() async {
    await _player.stop();
    setState(() {});
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _onEarned(int earned) {
    if (_timeUp) return;
    setState(() {
      _sessionPoints += earned;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Play')),
      body: Stack(
        children: [
          Positioned.fill(
            child: TakePictureScreen(
              camera: widget.camera,
              vision: widget.vision,
              captureEnabled: !_timeUp,
              onEarned: _onEarned,
              externalTotalPoints: _sessionPoints,
              showExternalTotalAsTotal: true,
              usedLabels: _usedLabels,
              onCommittedLabels: (labels) {
                _usedLabels.addAll(labels.map((e) => e.trim().toLowerCase()));
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _timeUp ? 'Time Up!' : '残り: $_remaining s',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (_timeUp)
            Positioned.fill(
              child: Container(
                color: const Color(0x88000000),
                child: Center(
                  child: Text(
                    '獲得: $_sessionPoints points',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _BootstrapScreen extends StatelessWidget {
  final CameraDescription camera;

  const _BootstrapScreen({required this.camera});

  Future<VisionService> _loadVision() async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'callExternalApi',
    );
    final res = await callable({});
    final apiKey = res.data['apiKey'];
    return ClientDirectVisionAdapter(apiKey: apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VisionService>(
      future: _loadVision(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('初期化エラー: ${snapshot.error}')),
          );
        }
        final vision = snapshot.data!;
        return TakePictureScreen(camera: camera, vision: vision);
      },
    );
  }
}

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

      final result = await Navigator.of(context).push<EarnResult>(
        MaterialPageRoute<EarnResult>(
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            vision: widget.vision,
            usedLabels: widget.usedLabels,
          ),
        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'total ${widget.showExternalTotalAsTotal && widget.externalTotalPoints != null ? widget.externalTotalPoints! : _totalPoints} points',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
        onPressed: widget.captureEnabled ? () => _captureAndAnalyze(context) : null,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final VisionService vision;
  final Set<String>? usedLabels;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.vision,
    this.usedLabels,
  });

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DataTransmissionDialog(
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed != true) {
      Navigator.of(context).pop();
      return;
    }

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

  List<String> _currentNormalizedLabels() {
    final set = <String>{};
    for (final l in _result.labels) {
      final n = l.description.trim().toLowerCase();
      if (n.isNotEmpty) set.add(n);
    }
    return set.toList();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存エラー: $e')));
    }
  }

  int _headPoint(String label) {
    final s = label.trim();
    if (s.isEmpty) return 0;
    final code = s.codeUnitAt(0);
    final isDigit = code >= 48 && code <= 57;
    final isUpper = code >= 65 && code <= 90;
    final isLower = code >= 97 && code <= 122;
    if (isDigit) return 4;
    if (!(isUpper || isLower)) return 5;
    final lower = s[0].toLowerCase();

    if (lower == 'x') return 3;
    if (lower == 'q') return 2;
    return 1;
  }

  int _labelScore(String description) {
    final hp = _headPoint(description);
    return description.length * hp;
  }

  int _totalScore(Iterable<VisionLabel> labels) {
    var sum = 0;
    for (final l in labels) {
      sum += _labelScore(l.description);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.file(File(widget.imagePath));
    final earnedPoints = _totalScore(_result.labels);
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
              child: CustomPaint(painter: _OverlayPainter(result: _result)),
            ),
          if (!_loading && _error == null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 56,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'get ${_totalScore(_result.labels)} points',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final current = _currentNormalizedLabels();
          final used = widget.usedLabels ?? const {};
          final hasDup = current.any((e) => used.contains(e));
          if (hasDup) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登録済み')),
            );
            return;
          }
          Navigator.of(context).pop<EarnResult>(
            EarnResult(earned: earnedPoints, labels: current),
          );
        },
        icon: const Icon(Icons.card_giftcard),
        label: const Text('ポイント獲得'),
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
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.yellow, fontSize: 14),
        ),
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
