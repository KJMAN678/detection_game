import 'package:flutter_test/flutter_test.dart';
import 'package:detection_game/models/vision_result.dart';

void main() {
  group('VisionResult models', () {
    test('VisionResult.empty has empty lists', () {
      expect(VisionResult.empty.objects, isEmpty);
      expect(VisionResult.empty.labels, isEmpty);
    });

    test('BBox stores coordinates correctly', () {
      const bbox = BBox(x: 0.1, y: 0.2, w: 0.3, h: 0.4);
      expect(bbox.x, 0.1);
      expect(bbox.y, 0.2);
      expect(bbox.w, 0.3);
      expect(bbox.h, 0.4);
    });

    test('VisionObject stores name, bbox and optional score', () {
      const bbox = BBox(x: 0, y: 0, w: 1, h: 1);
      const obj = VisionObject(name: 'person', bbox: bbox, score: 0.9);
      expect(obj.name, 'person');
      expect(obj.bbox, same(bbox));
      expect(obj.score, closeTo(0.9, 1e-9));
    });

    test('VisionLabel stores description and optional score', () {
      const label = VisionLabel(description: 'cat', score: 0.8);
      expect(label.description, 'cat');
      expect(label.score, closeTo(0.8, 1e-9));
    });

    test('VisionResult stores given lists', () {
      const bbox = BBox(x: 0, y: 0, w: 1, h: 1);
      const obj = VisionObject(name: 'bottle', bbox: bbox);
      const label = VisionLabel(description: 'bottle');
      const result = VisionResult(objects: [obj], labels: [label]);
      expect(result.objects.length, 1);
      expect(result.labels.length, 1);
      expect(result.objects.first.name, 'bottle');
      expect(result.labels.first.description, 'bottle');
    });
  });
}
