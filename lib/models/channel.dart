class ChannelCategory {
  final String id;
  final String name;

  ChannelCategory({required this.id, required this.name});
}

class Channel {
  final String id;
  final String name;
  final String? logo;
  final String groupTitle;
  final String streamUrl;

  Channel({
    required this.id,
    required this.name,
    this.logo,
    required this.groupTitle,
    required this.streamUrl,
  });
}

class Program {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final String? category;

  Program({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    this.category,
  });

  bool get isNowPlaying => 
    DateTime.now().isAfter(start) && DateTime.now().isBefore(end);
}
