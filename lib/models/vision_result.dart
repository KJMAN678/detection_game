class BBox {
  final double x;
  final double y;
  final double w;
  final double h;

  const BBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

class VisionObject {
  final String name;
  final BBox bbox;
  final double? score;

  const VisionObject({
    required this.name,
    required this.bbox,
    this.score,
  });
}

class VisionLabel {
  final String description;
  final double? score;

  const VisionLabel({
    required this.description,
    this.score,
  });
}

class VisionResult {
  final List<VisionObject> objects;
  final List<VisionLabel> labels;

  const VisionResult({
    required this.objects,
    required this.labels,
  });

  static const empty = VisionResult(objects: [], labels: []);
}
