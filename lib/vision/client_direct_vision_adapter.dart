import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../models/vision_result.dart';
import 'vision_service.dart';

class ClientDirectVisionAdapter implements VisionService {
  final String apiKey;
  final int maxLongEdge;
  final int jpegQuality;

  ClientDirectVisionAdapter({
    required this.apiKey,
    this.maxLongEdge = 1280,
    this.jpegQuality = 85,
  });

  @override
  Future<VisionResult> analyze({
    required Uint8List imageBytes,
    required List<VisionMode> modes,
  }) async {
    final processed = _compress(imageBytes);
    final requests = <Map<String, dynamic>>[];
    if (modes.contains(VisionMode.objects)) {
      requests.add({'type': 'OBJECT_LOCALIZATION'});
    }
    if (modes.contains(VisionMode.labels)) {
      requests.add({'type': 'LABEL_DETECTION', 'maxResults': 10});
    }

    final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Encode(processed)},
          'features': requests,
        }
      ]
    });

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (res.statusCode != 200) {
      return VisionResult.empty;
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final responses = decoded['responses'] as List<dynamic>? ?? [];
    if (responses.isEmpty) {
      return VisionResult.empty;
    }
    final first = responses.first as Map<String, dynamic>;

    final objects = <VisionObject>[];
    final labels = <VisionLabel>[];

    final localizedObjectAnnotations = first['localizedObjectAnnotations'] as List<dynamic>? ?? [];
    for (final o in localizedObjectAnnotations) {
      final name = (o['name'] as String?) ?? '';
      final score = (o['score'] as num?)?.toDouble();
      final vb = o['boundingPoly'] as Map<String, dynamic>?;
      final norm = _normalizedBBoxFromVertices(vb);
      if (norm != null) {
        objects.add(VisionObject(name: name, bbox: norm, score: score));
      }
    }

    final labelAnnotations = first['labelAnnotations'] as List<dynamic>? ?? [];
    for (final l in labelAnnotations) {
      final description = (l['description'] as String?) ?? '';
      final score = (l['score'] as num?)?.toDouble();
      labels.add(VisionLabel(description: description, score: score));
    }

    return VisionResult(objects: objects, labels: labels);
  }

  Uint8List _compress(Uint8List input) {
    try {
      final original = img.decodeImage(input);
      if (original == null) return input;

      final w = original.width;
      final h = original.height;
      final longEdge = w > h ? w : h;
      img.Image toEncode = original;

      if (longEdge > maxLongEdge) {
        final scale = maxLongEdge / longEdge;
        final nw = (w * scale).round();
        final nh = (h * scale).round();
        toEncode = img.copyResize(original, width: nw, height: nh);
      }

      return Uint8List.fromList(img.encodeJpg(toEncode, quality: jpegQuality));
    } catch (_) {
      return input;
    }
  }

  BBox? _normalizedBBoxFromVertices(Map<String, dynamic>? boundingPoly) {
    if (boundingPoly == null) return null;
    final vertices = boundingPoly['normalizedVertices'] as List<dynamic>?;

    if (vertices == null || vertices.isEmpty) {
      final v = boundingPoly['vertices'] as List<dynamic>? ?? [];
      if (v.isEmpty) return null;
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;
      for (final p in v) {
        final px = (p['x'] as num?)?.toDouble() ?? 0;
        final py = (p['y'] as num?)?.toDouble() ?? 0;
        if (px < minX) minX = px;
        if (py < minY) minY = py;
        if (px > maxX) maxX = px;
        if (py > maxY) maxY = py;
      }
      if (!minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite) {
        return null;
      }
      final w = (maxX - minX);
      final h = (maxY - minY);
      if (w <= 0 || h <= 0) return null;
      return BBox(x: minX, y: minY, w: w, h: h);
    } else {
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = -double.infinity;
      double maxY = -double.infinity;
      for (final p in vertices) {
        final px = (p['x'] as num?)?.toDouble() ?? 0;
        final py = (p['y'] as num?)?.toDouble() ?? 0;
        if (px < minX) minX = px;
        if (py < minY) minY = py;
        if (px > maxX) maxX = px;
        if (py > maxY) maxY = py;
      }
      if (!minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite) {
        return null;
      }
      final w = (maxX - minX);
      final h = (maxY - minY);
      if (w <= 0 || h <= 0) return null;
      return BBox(x: minX, y: minY, w: w, h: h);
    }
  }
}
