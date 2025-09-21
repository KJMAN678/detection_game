import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/screens/home/home_controller.dart';
import 'package:detection_game/models/vision_result.dart';
import 'package:detection_game/utils/data_service.dart';
import 'package:detection_game/vision/vision_service.dart';

class _FakeDataService extends DataService {
  @override
  Future<String> fetchVisionApiKey() async => 'fake-key';
}

class _FakeVisionService implements VisionService {
  @override
  Future<VisionResult> analyze({required Uint8List imageBytes, required List<VisionMode> modes}) async {
    return VisionResult.empty;
  }
}

void main() {
  test('visionServiceProvider resolves with api key', () async {
    final container = ProviderContainer(
      overrides: [
        dataServiceProvider.overrideWithValue(_FakeDataService()),
      ],
    );
    addTearDown(container.dispose);
    final vision = await container.read(visionServiceProvider.future);
    expect(vision, isA<VisionService>());
  });
}
