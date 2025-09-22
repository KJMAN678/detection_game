import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/screens/home/home_controller.dart';
import 'package:detection_game/vision/vision_service.dart';

void main() {
  test('visionServiceProvider provides VisionService', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vision = container.read(visionServiceProvider);
    expect(vision, isA<VisionService>());
  });
}
