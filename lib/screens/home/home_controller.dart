import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/utils/data_service.dart';
import 'package:detection_game/vision/vision_service.dart';
import 'package:detection_game/vision/client_direct_vision_adapter.dart';

final dataServiceProvider = Provider<DataService>((ref) => DataService());

final visionServiceProvider = FutureProvider<VisionService>((ref) async {
  final key = await ref.read(dataServiceProvider).fetchVisionApiKey();
  return ClientDirectVisionAdapter(apiKey: key);
});
