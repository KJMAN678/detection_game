import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:detection_game/vision/vision_service.dart';
import 'package:detection_game/core/constants.dart' as app_const;
import 'widgets/take_picture_screen.dart';

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
  int _remaining = app_const.Durations.gameLengthSeconds;
  final Set<String> _usedLabels = {};

  @override
  void initState() {
    super.initState();
    _startGame();
  }
  Future<void> _startGame() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/MusMus-BGM-125.mp3'));
    _timer = Timer.periodic(app_const.Durations.gameTick, (t) async {
      if (!mounted) return;
      setState(() {
        final next = _remaining - 1;
        _remaining = next < 0 ? 0 : next;
        if (next <= 0) {
          _timeUp = true;
          t.cancel();
        }
      });
      if (_timeUp) {
        await _player.stop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
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
              onEarned: (earned) {
                if (_timeUp) return;
                setState(() {
                  _sessionPoints += earned;
                });
              },
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
