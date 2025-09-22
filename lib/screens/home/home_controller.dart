import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:detection_game/utils/data_service.dart';
import 'package:detection_game/vision/vision_service.dart';
import 'package:detection_game/vision/client_direct_vision_adapter.dart';

final dataServiceProvider = Provider<DataService>((ref) => DataService());

final visionServiceProvider = Provider<VisionService>((ref) {
  // Cloud Functions 経由に変更したため API キー取得は不要
  return ClientDirectVisionAdapter();
});
