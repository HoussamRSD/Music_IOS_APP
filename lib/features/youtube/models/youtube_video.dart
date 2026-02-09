class YouTubeVideo {
  final String id;
  final String title;
  final String author;
  final Duration duration;
  final String thumbnailUrl;
  final int viewCount;
  final DateTime? uploadDate;

  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    this.viewCount = 0,
    this.uploadDate,
  });
}
