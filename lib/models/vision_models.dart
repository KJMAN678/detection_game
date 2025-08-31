class VisionBBox {
  final double x;
  final double y;
  final double w;
  final double h;
  const VisionBBox({required this.x, required this.y, required this.w, required this.h});
  factory VisionBBox.fromJson(Map<String, dynamic> json) =>
      VisionBBox(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        w: (json['w'] as num).toDouble(),
        h: (json['h'] as num).toDouble(),
      );
  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'w': w, 'h': h};
}

class VisionObject {
  final String name;
  final double score;
  final VisionBBox bbox;
  const VisionObject({required this.name, required this.score, required this.bbox});
  factory VisionObject.fromJson(Map<String, dynamic> json) =>
      VisionObject(
        name: json['name'] as String,
        score: (json['score'] as num).toDouble(),
        bbox: VisionBBox.fromJson(json['bbox'] as Map<String, dynamic>),
      );
  Map<String, dynamic> toJson() => {'name': name, 'score': score, 'bbox': bbox.toJson()};
}

class VisionLabel {
  final String description;
  final double score;
  const VisionLabel({required this.description, required this.score});
  factory VisionLabel.fromJson(Map<String, dynamic> json) =>
      VisionLabel(
        description: json['description'] as String,
        score: (json['score'] as num).toDouble(),
      );
  Map<String, dynamic> toJson() => {'description': description, 'score': score};
}

class VisionResult {
  final List<VisionObject> objects;
  final List<VisionLabel> labels;
  const VisionResult({required this.objects, required this.labels});
  factory VisionResult.fromJson(Map<String, dynamic> json) => VisionResult(
        objects: (json['objects'] as List<dynamic>? ?? [])
            .map((e) => VisionObject.fromJson(e as Map<String, dynamic>))
            .toList(),
        labels: (json['labels'] as List<dynamic>? ?? [])
            .map((e) => VisionLabel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'objects': objects.map((e) => e.toJson()).toList(),
        'labels': labels.map((e) => e.toJson()).toList(),
      };
}
