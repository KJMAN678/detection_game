import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gameplay_model.dart';

class GameplayController extends StateNotifier<GameplayState> {
  GameplayController({AudioPlayer? player, bool enableAudio = true})
      : _enableAudio = enableAudio,
        _player = enableAudio ? (player ?? AudioPlayer()) : null,
        super(const GameplayState());

  final bool _enableAudio;
  final AudioPlayer? _player;
  Timer? _timer;

  Future<void> start() async {
    if (_enableAudio) {
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.play(AssetSource('sounds/MusMus-BGM-125.mp3'));
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final next = state.remaining - 1;
      if (next <= 0) {
        _timer?.cancel();
        if (_enableAudio) {
          await _player!.stop();
        }
        state = state.copyWith(remaining: 0, timeUp: true);
        return;
      }
      state = state.copyWith(remaining: next);
    });
  }

  void onEarned(int earned) {
    if (state.timeUp) return;
    state = state.copyWith(sessionPoints: state.sessionPoints + earned);
  }

  void addCommittedLabels(Iterable<String> labels) {
    final updated = {
      ...state.usedLabels,
      ...labels.map((e) => e.trim().toLowerCase()),
    };
    state = state.copyWith(usedLabels: updated);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player?.dispose();
    super.dispose();
  }
}

final gameplayControllerProvider =
    StateNotifierProvider.autoDispose<GameplayController, GameplayState>(
  (ref) => GameplayController(),
);
