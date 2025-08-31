import 'dart:convert';

class VisionLabel {
  final String name;
  final double score;

  const VisionLabel({
    required this.name,
    required this.score,
  });

  VisionLabel copyWith({
    String? name,
    double? score,
  }) {
    return VisionLabel(
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
    };
  }

  factory VisionLabel.fromMap(Map<String, dynamic> map) {
    return VisionLabel(
      name: map['name'] as String? ?? '',
      score: (map['score'] is int) ? (map['score'] as int).toDouble() : (map['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory VisionLabel.fromJson(String source) => VisionLabel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisionLabel && other.name == name && other.score == score;
  }

  @override
  int get hashCode => name.hashCode ^ score.hashCode;
}

class VisionBox {
  final double x;
  final double y;
  final double width;
  final double height;

  const VisionBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  VisionBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return VisionBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory VisionBox.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) {
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return 0.0;
    }

    return VisionBox(
      x: _toDouble(map['x']),
      y: _toDouble(map['y']),
      width: _toDouble(map['width']),
      height: _toDouble(map['height']),
    );
  }

  String toJson() => json.encode(toMap());

  factory VisionBox.fromJson(String source) => VisionBox.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisionBox && other.x == x && other.y == y && other.width == width && other.height == height;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode;
}

class VisionDetection {
  final VisionLabel label;
  final VisionBox? box;

  const VisionDetection({
    required this.label,
    this.box,
  });

  VisionDetection copyWith({
    VisionLabel? label,
    VisionBox? box,
  }) {
    return VisionDetection(
      label: label ?? this.label,
      box: box ?? this.box,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label.toMap(),
      'box': box?.toMap(),
    };
  }

  factory VisionDetection.fromMap(Map<String, dynamic> map) {
    return VisionDetection(
      label: VisionLabel.fromMap(map['label'] as Map<String, dynamic>),
      box: map['box'] != null ? VisionBox.fromMap(map['box'] as Map<String, dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory VisionDetection.fromJson(String source) => VisionDetection.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisionDetection && other.label == label && other.box == box;
  }

  @override
  int get hashCode => label.hashCode ^ box.hashCode;
}

class VisionResult {
  final List<VisionDetection> detections;
  final DateTime timestamp;

  const VisionResult({
    required this.detections,
    required this.timestamp,
  });

  VisionResult copyWith({
    List<VisionDetection>? detections,
    DateTime? timestamp,
  }) {
    return VisionResult(
      detections: detections ?? this.detections,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'detections': detections.map((x) => x.toMap()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VisionResult.fromMap(Map<String, dynamic> map) {
    return VisionResult(
      detections: (map['detections'] as List<dynamic>? ?? [])
          .map((e) => VisionDetection.fromMap(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String toJson() => json.encode(toMap());

  factory VisionResult.fromJson(String source) => VisionResult.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisionResult && _listEquals(other.detections, detections) && other.timestamp == timestamp;
  }

  @override
  int get hashCode => detections.hashCode ^ timestamp.hashCode;

  static bool _listEquals(List a, List b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
