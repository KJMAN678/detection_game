import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;

import '../models/vision_result.dart';
import 'vision_service.dart';

class ClientDirectVisionAdapter implements VisionService {
  final int maxLongEdge;
  final int jpegQuality;

  ClientDirectVisionAdapter({
    this.maxLongEdge = 1280,
    this.jpegQuality = 85,
  });

  @override
  Future<VisionResult> analyze({
    required Uint8List imageBytes,
    required List<VisionMode> modes,
  }) async {
    final processed = _compress(imageBytes);
    // 圧縮後の画像サイズ（正規化に利用）
    final processedImage = img.decodeImage(processed);
    final imgW = processedImage?.width;
    final imgH = processedImage?.height;
    final requests = <Map<String, dynamic>>[];
    if (modes.contains(VisionMode.objects)) {
      requests.add({'type': 'OBJECT_LOCALIZATION'});
    }
    if (modes.contains(VisionMode.labels)) {
      requests.add({'type': 'LABEL_DETECTION', 'maxResults': 10});
    }

    final imageBase64 = base64Encode(processed);

    // Cloud Functions 経由で Vision API を呼び出す
    final fns = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = fns.httpsCallable('analyzeImage');
    final resp = await callable.call<Map<String, dynamic>>({
      'imageBase64': imageBase64,
      // サーバ側で参照する場合に備えて、要求した機能も送る
      'features': requests,
    });

    final decoded = resp.data as Map<String, dynamic>? ?? {};
    final responses = decoded['responses'] as List<dynamic>? ?? [];
    if (responses.isEmpty) {
      throw Exception('Vision API returned empty responses');
    }
    final first = responses.first as Map<String, dynamic>;

    final objects = <VisionObject>[];
    final labels = <VisionLabel>[];

    final localizedObjectAnnotations =
        first['localizedObjectAnnotations'] as List<dynamic>? ?? [];
    for (final o in localizedObjectAnnotations) {
      final name = (o['name'] as String?) ?? '';
      final score = (o['score'] as num?)?.toDouble();
      final vb = o['boundingPoly'] as Map<String, dynamic>?;
      final norm = _normalizedBBoxFromVertices(vb, imgW, imgH);
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

    final effectiveLabels = objects.isEmpty ? <VisionLabel>[] : labels;
    return VisionResult(objects: objects, labels: effectiveLabels);
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

  BBox? _normalizedBBoxFromVertices(
    Map<String, dynamic>? boundingPoly,
    int? imgW,
    int? imgH,
  ) {
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
      if (!minX.isFinite ||
          !minY.isFinite ||
          !maxX.isFinite ||
          !maxY.isFinite) {
        return null;
      }
      final w = (maxX - minX);
      final h = (maxY - minY);
      if (w <= 0 || h <= 0) return null;
      // 画像サイズが分かる場合は 0〜1 に正規化する
      if (imgW != null && imgH != null && imgW > 0 && imgH > 0) {
        final nx = (minX / imgW).clamp(0.0, 1.0);
        final ny = (minY / imgH).clamp(0.0, 1.0);
        final nw = (w / imgW).clamp(0.0, 1.0);
        final nh = (h / imgH).clamp(0.0, 1.0);
        if (nw <= 0 || nh <= 0) return null;
        return BBox(x: nx, y: ny, w: nw, h: nh);
      }
      // 画像サイズが不明なら描画に使えないので null を返す
      return null;
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
      if (!minX.isFinite ||
          !minY.isFinite ||
          !maxX.isFinite ||
          !maxY.isFinite) {
        return null;
      }
      final w = (maxX - minX);
      final h = (maxY - minY);
      if (w <= 0 || h <= 0) return null;
      return BBox(x: minX, y: minY, w: w, h: h);
    }
  }
}
