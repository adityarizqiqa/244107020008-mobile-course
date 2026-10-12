/// Pure Domain Entity for Announcement (Campus Notification)
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    this.author = 'Admin Kampus JTI',
    this.category = 'Akademik',
  });

  final int id;
  final String title;
  final String content;
  final DateTime publishedAt;
  final String author;
  final String category;
}
