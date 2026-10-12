import '../../domain/entities/announcement.dart';

/// Data model for Announcement with JSON/Map mapping
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.content,
    required super.publishedAt,
    super.author = 'Admin Kampus JTI',
    super.category = 'Akademik',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'published_at': publishedAt.toIso8601String(),
        'author': author,
        'category': category,
      };

  factory AnnouncementModel.fromMap(Map<String, Object?> map) {
    return AnnouncementModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      publishedAt: DateTime.tryParse(map['published_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      author: map['author'] as String? ?? 'Admin Kampus JTI',
      category: map['category'] as String? ?? 'Akademik',
    );
  }

  Announcement toEntity() => Announcement(
        id: id,
        title: title,
        content: content,
        publishedAt: publishedAt,
        author: author,
        category: category,
      );
}
