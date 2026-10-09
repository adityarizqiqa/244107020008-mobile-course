import 'package:dio/dio.dart';
import '../models/comment.dart';

/// Repository layer yang menangani komunikasi data untuk entity Comment
class CommentRepository {
  CommentRepository(this._dio);

  // Dio client yang di-inject dari provider
  final Dio _dio;

  /// Mengambil daftar komentar berdasarkan [postId]
  /// Dilengkapi timeout eksplisit 10 detik per-request sesuai requirement
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final data = response.data ?? [];
    return data
        .whereType<Map>()
        .map((e) => Comment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
