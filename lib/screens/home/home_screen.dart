import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/core/widgets/loading_indicator.dart';
import 'package:detection_game/core/constants.dart';
import 'package:detection_game/screens/home/home_controller.dart';

class HomeScreen extends ConsumerWidget {
  final CameraDescription camera;
  const HomeScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visionAsync = ref.watch(visionServiceProvider);
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
      body: visionAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('初期化エラー'),
              Text('$e', style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(visionServiceProvider),
                child: const Text('リトライ'),
              ),
            ],
          ),
        ),
        data: (vision) => Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('ゲーム開始'),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.gamePlay,
                arguments: {'camera': camera, 'vision': vision},
              );
            },
          ),
        ),
      ),
    );
  }
}
