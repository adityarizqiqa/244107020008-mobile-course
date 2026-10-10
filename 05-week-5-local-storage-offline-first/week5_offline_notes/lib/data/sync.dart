import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'local/db.dart';
import 'repositories/note_repository.dart';

class Post {
  final int id;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
      };
}

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class IsSyncingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final isSyncingProvider =
    NotifierProvider<IsSyncingNotifier, bool>(IsSyncingNotifier.new);

final lastSyncTimeProvider =
    NotifierProvider<LastSyncTimeNotifier, DateTime?>(LastSyncTimeNotifier.new);

class LastSyncTimeNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void update(DateTime dt) => state = dt;
}

// Fallback memory untuk web
final List<Post> _webCachedPosts = [];

Future<List<Post>> readCachedPosts({
  Future<Database> Function()? openDb,
}) async {
  if (kIsWeb) {
    return List<Post>.from(_webCachedPosts);
  }

  final db = await (openDb ?? openNotesDb)();
  final rows = await db.query('cached_posts', orderBy: 'id ASC');
  return rows.map((r) {
    final payload = r['payload'] as String;
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return Post.fromJson(json);
  }).toList();
}

Future<void> saveCachedPosts(
  List<Post> posts, {
  Future<Database> Function()? openDb,
}) async {
  if (kIsWeb) {
    _webCachedPosts.clear();
    _webCachedPosts.addAll(posts);
    return;
  }

  final db = await (openDb ?? openNotesDb)();
  final batch = db.batch();
  final nowStr = DateTime.now().toIso8601String();
  for (final post in posts) {
    batch.insert(
      'cached_posts',
      {
        'id': post.id,
        'payload': jsonEncode(post.toJson()),
        'cached_at': nowStr,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  // Aturan resolusi konflik: Last-Write-Wins berdasarkan updated_at.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final isOffline = ref.watch(forceOfflineProvider);

  // 1. Segera kembalikan cache agar UI tidak blank saat offline (Cache-first read).
  final cached = await readCachedPosts();

  // 2. Di background: fetch jaringan bila tidak sedang offline -> simpan ke cached_posts.
  if (!isOffline) {
    Future.microtask(() async {
      try {
        final response = await http
            .get(Uri.parse('https://jsonplaceholder.typicode.com/posts'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final list = jsonDecode(response.body) as List;
          final freshPosts = list
              .take(20)
              .map((e) => Post.fromJson(e as Map<String, dynamic>))
              .toList();

          await saveCachedPosts(freshPosts);
          if (cached.isEmpty) {
            ref.invalidateSelf();
          }
        }
      } catch (_) {
        // Abaikan error jaringan saat background fetch, UI tetap menampilkan cache.
      }
    });
  }

  return cached;
});
