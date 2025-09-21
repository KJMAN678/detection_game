import 'package:flutter_test/flutter_test.dart';
import 'package:detection_game/screens/home/gameplay_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameplayController increments points and tracks labels', () async {
    final controller = GameplayController(enableAudio: false);
    expect(controller.state.sessionPoints, 0);
    controller.onEarned(5);
    expect(controller.state.sessionPoints, 5);

    controller.addCommittedLabels([' Apple ', 'banana', 'BANANA']);
    expect(controller.state.usedLabels.contains('apple'), true);
    expect(controller.state.usedLabels.contains('banana'), true);
  });

  test('GameplayController start counts down and timeUp triggers', () async {
    final controller = GameplayController(enableAudio: false);
    await controller.start();
    await Future.delayed(const Duration(seconds: 2));
    expect(controller.state.remaining <= 9, true);
    controller.dispose();
  });
}
