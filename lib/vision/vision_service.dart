import 'dart:typed_data';

import '../models/vision_result.dart';

enum VisionMode {
  objects,
  labels,
}

abstract class VisionService {
  Future<VisionResult> analyze({
    required Uint8List imageBytes,
    required List<VisionMode> modes,
  });
}
