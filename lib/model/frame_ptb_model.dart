enum FramePtbType {
  type1x3,
  type2x3,
}

enum FramePtbContentType {
  beautiful,
  funny,
  romantic,
  creative,
  classic,
  modern,
  vintage,
  blackandwhite,
  color,
  gradient,
  pattern,
  abstract,
  nature,
  city,
  animal,
  food,
  sport,
  music,
  art,
  travel,
  fashion,
  technology,
  other,
}

class FramePtbModel {
  final String id;
  final FramePtbType type;
  final String image;
  final String name;
  final String subtitle;
  FramePtbModel({
    required this.id,
    required this.type,
    required this.image,
    required this.name,
    required this.subtitle,
  });
}
