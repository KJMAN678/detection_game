import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/vision_models.dart';

class ClientDirectVisionAdapter {
  static const _apiKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');

  static Future<VisionResult> analyzeImageFile(File file, {bool detectObjects = true, bool detectLabels = true}) async {
    if (_apiKey.isEmpty) {
      throw Exception('VISION_API_KEY is not set');
    }
    final bytes = await file.readAsBytes();
    final imgContent = base64Encode(bytes);

    final features = <Map<String, dynamic>>[];
    if (detectObjects) {
      features.add({'type': 'OBJECT_LOCALIZATION'});
    }
    if (detectLabels) {
      features.add({'type': 'LABEL_DETECTION'});
    }

    final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_apiKey');
    final body = {
      'requests': [
        {
          'image': {'content': imgContent},
          'features': features,
        }
      ]
    };

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Vision API error: ${resp.statusCode} ${resp.body}');
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final responses = (json['responses'] as List?) ?? [];
    if (responses.isEmpty) {
      return const VisionResult(objects: [], labels: []);
    }
    final r = responses.first as Map<String, dynamic>;

    final objectsJson = (r['localizedObjectAnnotations'] as List?) ?? [];
    final objects = objectsJson.map((oRaw) {
      final o = oRaw as Map<String, dynamic>;
      final poly = o['boundingPoly'] as Map<String, dynamic>?;
      final verts = (poly?['normalizedVertices'] as List?) ?? [];
      final xs = verts.map((vRaw) => ((vRaw as Map<String, dynamic>)['x'] ?? 0).toDouble()).toList();
      final ys = verts.map((vRaw) => ((vRaw as Map<String, dynamic>)['y'] ?? 0).toDouble()).toList();
      final minX = xs.isEmpty ? 0.0 : xs.reduce((a, b) => a < b ? a : b);
      final minY = ys.isEmpty ? 0.0 : ys.reduce((a, b) => a < b ? a : b);
      final maxX = xs.isEmpty ? 0.0 : xs.reduce((a, b) => a > b ? a : b);
      final maxY = ys.isEmpty ? 0.0 : ys.reduce((a, b) => a > b ? a : b);
      return VisionObject(
        name: (o['name'] ?? '') as String,
        score: ((o['score'] ?? 0) as num).toDouble(),
        bbox: VisionBBox(
          x: minX,
          y: minY,
          w: (maxX - minX).clamp(0, 1).toDouble(),
          h: (maxY - minY).clamp(0, 1).toDouble(),
        ),
      );
    }).toList().cast<VisionObject>();

    final labelsJson = (r['labelAnnotations'] as List?) ?? [];
    final labels = labelsJson
        .map((lRaw) {
          final l = lRaw as Map<String, dynamic>;
          return VisionLabel(
            description: (l['description'] ?? '') as String,
            score: ((l['score'] ?? 0) as num).toDouble(),
          );
        })
        .toList()
        .cast<VisionLabel>();

    return VisionResult(objects: objects, labels: labels);
  }
}
