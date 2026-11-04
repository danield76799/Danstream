class SeriesCategory {
  final String id;
  final String name;

  SeriesCategory({required this.id, required this.name});
}

class Series {
  final String id;
  final String name;
  final String? cover;
  final String categoryId;

  Series({
    required this.id,
    required this.name,
    this.cover,
    required this.categoryId,
  });
}
