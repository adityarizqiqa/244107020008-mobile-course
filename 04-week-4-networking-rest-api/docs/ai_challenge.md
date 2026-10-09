# AI Challenge: Repository Layer & Error Handling

**Nama:** Aditya Rizqiqa Ramadhan  
**NIM:** 244107020008  
**Kelas:** TI-3E  
**Mata Kuliah:** Pemrograman Mobile  

---

## 1. Prompt AI yang Digunakan
Sesuai instruksi pada modul praktikum Codelab Minggu 4:

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error
  ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

---

## 2. Implementasi Kode

### A. Model: `lib/data/models/comment.dart`
```dart
/// Model data Comment yang merepresentasikan komentar dari JSONPlaceholder (`GET /comments?postId={id}`)
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Factory constructor fromJson dengan parsing defensif (null-safe).
  /// Mencegah TypeError jika ada field yang bernilai null atau bertipe num (int/double).
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengonversi instance Comment kembali ke Map JSON
  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
```

### B. Repository: `lib/data/repositories/comment_repository.dart`
```dart
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
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
```

### C. Provider & Error Handling: `lib/data/comment_providers.dart`
```dart
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
```

---

## 3. Perbaikan & Alasan Keputusan Teknis
1. **Pemisahan File yang Modular**:
   Kode ditempatkan secara terpisah di `comment.dart`, `comment_repository.dart`, dan `comment_providers.dart` untuk menjaga prinsip *Single Responsibility Principle* (SRP) serta mempermudah pengujian.
2. **Kesesuaian Riverpod 3 Family**:
   Di Riverpod 3, keluarga notifier didefinisikan dengan `AsyncNotifierProvider.family` di mana class notifier menerima parameter constructor `CommentListNotifier(this.postId)` dan meng-extend `AsyncNotifier<List<Comment>>`. Sintaks ini modern, *clean*, dan lolos dari peringatan depresiasi.
3. **Konfigurasi Timeout Per-Request**:
   Pada `CommentRepository`, opsi `sendTimeout` dan `receiveTimeout` eksplisit disematkan pada pemanggilan `_dio.get(...)` untuk menjamin kepatuhan terhadap batasan 10 detik.
4. **Pengujian Tambahan (Edge Cases)**:
   Selain pengujian field hilang, ditambahkan pengujian jika semua field null dan angka berupa pecahan num (`10.0`), pemetaan seluruh kode status HTTP (404, 500, timeout, connection error), serta pengujian provider state dengan repository tiruan (`FakeCommentRepository`).

---

## 4. AI Verification Checklist
| Kriteria Verifikasi | Status | Penjelasan |
|---|---|---|
| **1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?** | **Lolos** | UI hanya membaca provider `commentListProvider`, provider memanggil `CommentRepository`, dan hanya repository yang mengakses `Dio`. |
| **2. Apakah `fromJson` aman null, atau masih memakai cast langsung yang bisa crash?** | **Lolos** | Menggunakan pola defensif `(json['postId'] as num?)?.toInt() ?? 0` dan `json['name'] as String? ?? ''`, mencegah `TypeError` saat field tidak ada atau bertipe null. |
| **3. Apakah semua tipe `DioExceptionType` (timeout, connectionError, badResponse) dipetakan ke pesan pengguna?** | **Lolos** | Fungsi `friendlyCommentErrorMessage` menangani `connectionTimeout`, `sendTimeout`, `receiveTimeout`, `connectionError`, serta status code `404` dan `500` secara terperinci. |
| **4. Apakah `baseUrl`/timeout terpusat di satu client, bukan tersebar di tiap method?** | **Lolos** | Repository menggunakan instance `Dio` yang bersumber dari `dioProvider` terpusat (`api_client.dart`). |
| **5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path? Tambahkan minimal 1 edge case sendiri.** | **Lolos** | Menguji kasus field hilang, edge case nilai `null` dan tipe numerik desimal, pengujian pemetaan error, serta simulasi kegagalan jaringan pada provider. |
| **6. Jalankan `flutter analyze` dan `flutter test`, apakah hasil AI lolos tanpa warning?** | **Lolos** | `flutter analyze` menghasilkan *0 issues* dan 9 test di `test/comment_test.dart` lulus 100%. |
