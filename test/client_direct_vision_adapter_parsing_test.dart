import 'package:detection_game/models/vision_result.dart';
import 'package:flutter_test/flutter_test.dart';

/// This test verifies that maps/lists coming from a dynamic source like
/// Cloud Functions (typed as Map<Object?, Object?> / List<Object?>)
/// can be safely parsed by the logic in client_direct_vision_adapter.dart.
/// We replicate the parsing portion by simulating the 'first' response map
/// and ensuring downstream loops work with casted maps.
Map<String, dynamic> _castFirstForTest(Map<Object?, Object?> firstObj) {
  // Simulate the casting logic used in the adapter after the fix.
  return (firstObj as Map).cast<String, dynamic>();
}

void main() {
  test('safely handles Object?-keyed maps and lists for objects and labels', () {
    final first = <String, Object?>{
      'localizedObjectAnnotations': [
        {
          'name': 'Laptop',
          'score': 0.9,
          'boundingPoly': {
            'normalizedVertices': [
              {'x': 0.1, 'y': 0.1},
              {'x': 0.4, 'y': 0.4},
            ]
          }
        }
      ],
      'labelAnnotations': [
        {'description': 'electronics', 'score': 0.88}
      ]
    };

    final firstObj = (first as Map).cast<Object?, Object?>();

    final firstCasted = _castFirstForTest(firstObj);

    final localized = (firstCasted['localizedObjectAnnotations'] as List? ?? const [])
        .cast<Object?>()
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    expect(localized.length, 1);
    expect(localized.first['name'], 'Laptop');

    final vb = (localized.first['boundingPoly'] as Map?)?.cast<String, dynamic>();
    expect(vb, isNotNull);

    final labels = (firstCasted['labelAnnotations'] as List? ?? const [])
        .cast<Object?>()
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    expect(labels.length, 1);
    expect(labels.first['description'], 'electronics');

    // Construct VisionResult-like objects to ensure model compatibility.
    final objects = <VisionObject>[
      VisionObject(
        name: localized.first['name'] as String,
        bbox: const BBox(x: 0.1, y: 0.1, w: 0.3, h: 0.3),
        score: (localized.first['score'] as num?)?.toDouble(),
      )
    ];
    final labelModels = <VisionLabel>[
      VisionLabel(
        description: labels.first['description'] as String,
        score: (labels.first['score'] as num?)?.toDouble(),
      )
    ];

    final res = VisionResult(objects: objects, labels: labelModels);
    expect(res.objects.first.name, 'Laptop');
    expect(res.labels.first.description, 'electronics');
  });
}
