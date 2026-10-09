import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Provider untuk CommentRepository menggunakan dioProvider terpusat
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// AsyncNotifier untuk mengelola state komentar berdasarkan postId
class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  CommentListNotifier(this.postId);

  /// ID Post yang ingin diambil komentarnya
  final int postId;

  @override
  Future<List<Comment>> build() async {
    // Exception dari repository otomatis menjadi AsyncError
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(postId);
  }

  /// Memperbarui atau memuat ulang daftar komentar
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider family untuk komentar berdasarkan parameter postId
final commentListProvider =
    AsyncNotifierProvider.family<CommentListNotifier, List<Comment>, int>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,
);

/// Fungsi pemetaan pesan error ramah pengguna (user-friendly)
/// Menangani timeout, connection error, 404, dan 500 sesuai requirement AI Challenge
String friendlyCommentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout (10 detik). Silakan periksa jaringan Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) {
          return 'Komentar tidak ditemukan (Error 404).';
        }
        if (code == 500) {
          return 'Terjadi gangguan internal server (Error 500). Silakan coba beberapa saat lagi.';
        }
        return 'Gagal memuat data dari server ($code).';
      default:
        return 'Terjadi masalah jaringan saat memuat komentar.';
    }
  }
  return 'Terjadi kesalahan tidak terduga: $error';
}
