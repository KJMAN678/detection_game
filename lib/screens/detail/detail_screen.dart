import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:detection_game/models/vision_result.dart';
import 'package:detection_game/screens/detail/detail_model.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:detection_game/vision/vision_service.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  final VisionService vision;
  final Set<String>? usedLabels;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.vision,
    this.usedLabels,
  });

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  VisionResult _result = VisionResult.empty;
  bool _loading = false;
  String? _error;
  int? _imgW;
  int? _imgH;

  @override
  void initState() {
    super.initState();
    _loadImageDimension().then((_) => _analyze());
  }

  Future<void> _loadImageDimension() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _imgW = frame.image.width;
        _imgH = frame.image.height;
      });
    } catch (_) {}
  }

  Future<void> _analyze() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final sw = Stopwatch()..start();
      final res = await widget.vision.analyze(
        imageBytes: Uint8List.fromList(bytes),
        modes: const [VisionMode.objects, VisionMode.labels],
      );
      sw.stop();
      setState(() {
        _result = res;
      });
      debugPrint('analyze took ${sw.elapsedMilliseconds} ms');
      debugPrint('objects=${res.objects.length}, labels=${res.labels.length}');
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<String> _currentNormalizedLabels() {
    final set = <String>{};
    for (final l in _result.labels) {
      final n = l.description.trim().toLowerCase();
      if (n.isNotEmpty) set.add(n);
    }
    return set.toList();
  }

  Future<void> _saveToGallery() async {
    try {
      final ok = await GallerySaver.saveImage(widget.imagePath);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok == true ? 'ギャラリーに保存しました' : '保存に失敗しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存エラー: $e')));
    }
  }

  int _headPoint(String label) {
    final s = label.trim();
    if (s.isEmpty) return 0;
    final code = s.codeUnitAt(0);
    final isDigit = code >= 48 && code <= 57;
    final isUpper = code >= 65 && code <= 90;
    final isLower = code >= 97 && code <= 122;
    if (isDigit) return 4;
    if (!(isUpper || isLower)) return 5;
    final lower = s[0].toLowerCase();

    if (lower == 'x') return 3;
    if (lower == 'q') return 2;
    return 1;
  }

  int _labelScore(String description) {
    final hp = _headPoint(description);
    return description.length * hp;
  }

  int _totalScore(Iterable<VisionLabel> labels) {
    var sum = 0;
    for (final l in labels) {
      sum += _labelScore(l.description);
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.file(File(widget.imagePath), fit: BoxFit.contain);
    final earnedPoints = _totalScore(_result.labels);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
        actions: [
          IconButton(
            onPressed: _saveToGallery,
            icon: const Icon(Icons.save_alt),
            tooltip: 'ギャラリーに保存',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final hasDim =
              _imgW != null && _imgH != null && _imgW! > 0 && _imgH! > 0;
          final aspect = hasDim ? _imgW! / _imgH! : null;
          final overlay = CustomPaint(
            painter: _OverlayPainter(result: _result),
          );
          final imageStack = hasDim
              ? Center(
                  child: AspectRatio(
                    aspectRatio: aspect!,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageWidget,
                        if (!_loading && _error == null) overlay,
                      ],
                    ),
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    if (!_loading && _error == null) overlay,
                  ],
                );

          return Stack(
            children: [
              Positioned.fill(child: imageStack),
              if (_loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (_error != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.redAccent,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              if (!_loading && _error == null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 56,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'get ${_totalScore(_result.labels)} points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              if (!_loading && _error == null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _result.labels
                          .map(
                            (l) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l.description,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final current = _currentNormalizedLabels();
          final used = widget.usedLabels ?? const {};
          final hasDup = current.any((e) => used.contains(e));
          if (hasDup) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('登録済み')));
            return;
          }
          Navigator.of(
            context,
          ).pop<EarnResult>(EarnResult(earned: earnedPoints, labels: current));
        },
        icon: const Icon(Icons.card_giftcard),
        label: const Text('ポイント獲得'),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final VisionResult result;

  _OverlayPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    TextPainter textPainter(String text) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.yellow, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      return tp;
    }

    for (final o in result.objects) {
      final rect = Rect.fromLTWH(
        o.bbox.x * size.width,
        o.bbox.y * size.height,
        o.bbox.w * size.width,
        o.bbox.h * size.height,
      );
      canvas.drawRect(rect, boxPaint);

      final tp = textPainter(o.name);
      final offset = Offset(rect.left, rect.top - tp.height - 2);
      tp.paint(canvas, offset);
    }
    // 追加: 画面上部中央に検出ラベルを箇条書き（各行先頭に「・」）で表示
    if (result.objects.isNotEmpty) {
      final unique = <String, double?>{};
      for (final o in result.objects) {
        if (!unique.containsKey(o.name) || (o.score ?? -1) > (unique[o.name] ?? -1)) {
          unique[o.name] = o.score;
        }
      }
      final entries = unique.entries.toList()
        ..sort((a, b) {
          final sa = a.value ?? -1;
          final sb = b.value ?? -1;
          return sb.compareTo(sa);
        });
      final labels = entries.map((e) => e.key).toList();

      if (labels.isNotEmpty) {
        final style = const TextStyle(
          color: Color(0xFF212121),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        );
        final maxWidth = size.width * 0.9;
        const itemSpacing = 4.0;
        const paddingV = 8.0;
        const paddingH = 12.0;

        final painters = <TextPainter>[];
        double maxLineW = 0;
        double totalH = 0;

        for (final label in labels) {
          final lineText = '・$label';
          final tp = TextPainter(
            text: TextSpan(text: lineText, style: style),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            ellipsis: '…',
            maxLines: 1,
          )..layout(maxWidth: maxWidth);
          painters.add(tp);
          if (tp.width > maxLineW) {
            maxLineW = tp.width;
          }
          totalH += tp.height;
        }
        if (painters.isNotEmpty) {
          totalH += itemSpacing * (painters.length - 1);
        }

        final bgW = maxLineW + paddingH * 2;
        final bgH = totalH + paddingV * 2;
        final bgLeft = (size.width - bgW) / 2;
        const bgTop = 8.0;

        final bgPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85);
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bgLeft, bgTop, bgW, bgH),
          const Radius.circular(6),
        );
        canvas.drawRRect(rrect, bgPaint);

        double y = bgTop + paddingV;
        for (final tp in painters) {
          final textX = bgLeft + (bgW - tp.width) / 2;
          tp.paint(canvas, Offset(textX, y));
          y += tp.height + itemSpacing;
        }
      }
    }

  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}
