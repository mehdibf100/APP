class PackageItem {
  String title;
  double weight;
  double width;
  double height;

  PackageItem({
    required this.title,
    required this.weight,
    required this.width,
    required this.height,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      title: json['title'] ?? 'Unknown Package',
      weight: (json['weight'] ?? 0).toDouble(),
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'weight': weight,
      'width': width,
      'height': height,
    };
  }
}