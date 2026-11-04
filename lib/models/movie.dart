class MovieCategory {
  final String id;
  final String name;

  MovieCategory({required this.id, required this.name});
}

class Movie {
  final String id;
  final String name;
  final String? cover;
  final String categoryId;
  final String streamUrl;

  Movie({
    required this.id,
    required this.name,
    this.cover,
    required this.categoryId,
    required this.streamUrl,
  });
}
