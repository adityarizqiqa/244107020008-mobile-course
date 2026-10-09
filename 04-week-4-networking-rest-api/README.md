# Week 4: Networking & REST API

**Nama:** Aditya Rizqiqa Ramadhan  
**NIM:** 244107020008  
**Kelas:** TI-3E (Teknologi Informasi, Politeknik Negeri Malang)  

---

## Tujuan
Praktikum ini bertujuan untuk memahami dan mengimplementasikan integrasi jaringan HTTP dan REST API pada Flutter:
1. Memahami konsep HTTP, REST API, JSON serialization, dan deserialization yang aman terhadap `null`.
2. Menerapkan **Repository Pattern** agar UI tidak memanggil API atau client HTTP secara langsung.
3. Mengonfigurasi **Dio** secara terpusat (base URL, timeout, interceptor logging).
4. Menangani state asinkron secara reaktif (**Loading**, **Error**, **Empty**, **Data**) menggunakan `AsyncValue` dan `Riverpod`.
5. Mengimplementasikan **Pagination (Infinite Scroll)** dengan guard pencegah request ganda.
6. Menyelesaikan **AI Challenge** dengan verifikasi teknis arsitektur dan error handling.
7. Menerapkan **Refactoring Challenge** (ekstraksi widget `PostTile`, pemusatan error di `network_errors.dart`, rute detail via `go_router`) dan pengujian otomatis (unit & mock testing).

---

## Fitur Utama
- **Null-Safe JSON Serialization:** Parsing model `Post` dan `Comment` secara defensif untuk mencegah error runtime (`TypeError`).
- **Centralized Network Client:** Konfigurasi Dio terpusat di `lib/data/api_client.dart` dengan logging interceptor dan timeout.
- **Repository Layer:** Pemisahan logika komunikasi jaringan melalui `PostRepository` dan `CommentRepository`.
- **User-Friendly Error Handling:** Pemetaan exception jaringan (`DioException`) di `network_errors.dart` menjadi pesan ramah pengguna untuk timeout, offline/koneksi putus, error 404, dan 500.
- **Pagination Infinite Scroll:** Menggunakan `PagedPostsNotifier` dan `ScrollController` untuk memuat data bertahap per 10 item.
- **Post Detail & Comments Navigation:** Routing deklaratif dengan `go_router` (`/post/:id`) dengan pengambilan data dari cache list atau API via repository.
- **Reusable Component:** Ekstraksi komponen baris item ke dalam `PostTile`.
- **Comprehensive Testing:** 16 automated tests (model null-safety, mapping error, provider dengan repository tiruan, dan widget smoke test).

---

## Stack Teknologi
- **Framework:** Flutter (Dart)
- **HTTP Client:** `dio` (^5.11.1)
- **State Management:** `flutter_riverpod` (^3.4.3)
- **Navigation:** `go_router` (^18.0.2)
- **Testing:** `flutter_test`

---

## Cara Menjalankan
1. Masuk ke direktori proyek:
   ```bash
   cd week4_api
   ```
2. Jalankan `flutter pub get` untuk mengunduh dependencies:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi:
   ```bash
   flutter run
   ```
4. Jalankan pengujian:
   ```bash
   flutter test
   ```

---

## Refactoring Challenge

1. **Ekstraksi Widget `PostTile` (`lib/widgets/post_tile.dart`):**  
   Baris item `ListTile` pada list post diekstrak menjadi widget tersendiri yang menerima objek `Post` dan callback `onTap`, membuat `ListView.builder` lebih ringkas dan modular untuk diuji.
2. **Pemusatan Pesan Error (`lib/data/network_errors.dart`):**  
   Fungsi `friendlyErrorMessage` dipindahkan ke file mandiri `network_errors.dart` dan diekspor melalui `providers.dart` agar dapat digunakan secara konsisten oleh seluruh halaman (list, pagination, maupun detail).
3. **Halaman Detail Post dengan GoRouter (`/post/:id`):**  
   - Menambahkan rute `/post/:id` pada konfigurasi `GoRouter` di `lib/main.dart`.
   - Membuat halaman `PostDetailPage` (`lib/pages/post_detail_page.dart`) yang menampilkan `title`, `body` lengkap, serta daftar komentar (`Comment`).
   - State detail dikelola oleh `postDetailProvider`: data diambil langsung dari cache list jika sudah dimuat sebelumnya, atau memanggil repository `fetchPostById(id)` jika dibuka langsung via URL.

---

## AI Challenge: AI Verification Checklist

### 1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?
**Ya, UI tidak pernah memanggil Dio secara langsung.** Seluruh interaksi data dilakukan melalui provider (`commentListProvider` atau `postListProvider`) yang mengonsumsi repository (`CommentRepository` atau `PostRepository`). UI hanya bertugas sebagai konsumen reaktif dari `AsyncValue`.

### 2. Apakah `fromJson` aman null, atau masih memakai cast langsung yang bisa crash?
**Ya, sudah aman null.** Implementasi `Comment.fromJson` dan `Post.fromJson` menggunakan casting defensif seperti `(json['postId'] as num?)?.toInt() ?? 0` dan `json['name'] as String? ?? ''`, sehingga jika field bernilai null atau tidak ada, aplikasi tetap berjalan aman dengan nilai default fallback tanpa memicu `TypeError`.

### 3. Apakah semua tipe `DioExceptionType` (timeout, connectionError, badResponse) dipetakan ke pesan pengguna?
**Ya, seluruh tipe ditangani.** Fungsi `friendlyCommentErrorMessage` dan `friendlyErrorMessage` menangani:
- Timeout (`connectionTimeout`, `sendTimeout`, `receiveTimeout`) -> Memberitahukan koneksi lambat/timeout 10 detik.
- Koneksi gagal (`connectionError`) -> Menginstruksikan pemeriksaan koneksi internet.
- Bad Response (`badResponse`) -> Menangani status code spesifik seperti 404 (tidak ditemukan) dan 500 (gangguan internal server).

### 4. Apakah `baseUrl`/timeout terpusat di satu client, bukan tersebar di tiap method?
**Ya, terpusat.** Konfigurasi `baseUrl`, `headers`, default timeout, dan interceptor diatur terpusat di `createDio()` pada [api_client.dart](file:///d:/KULIAH%20TINGKAT%202/Semester%205/Repository/244107020008-mobile-course-1/04-week-4-networking-rest-api/week4_api/lib/data/api_client.dart), yang kemudian di-inject ke repository via `dioProvider`.

### 5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path? Tambahkan minimal 1 edge case sendiri.
**Ya, mencakup field hilang dan edge cases tambahan.** Unit test di [test/comment_test.dart](file:///d:/KULIAH%20TINGKAT%202/Semester%205/Repository/244107020008-mobile-course-1/04-week-4-networking-rest-api/week4_api/test/comment_test.dart) menguji:
1. Kasus field JSON hilang/tidak ada.
2. *Edge case* saat seluruh key bernilai `null` serta tipe data numerik berupa pecahan desimal `10.0`.
3. Pemetaan seluruh jenis error message.
4. Simulasi sukses dan gagal (network failure) pada provider menggunakan `FakeCommentRepository`.

### 6. Jalankan `flutter analyze` dan `flutter test`, apakah hasil AI lolos tanpa warning?
**Lolos tanpa issue.**
- `flutter analyze` menghasilkan: `No issues found!`.
- `flutter test` menghasilkan: `All tests passed!` (16 pengujian lolos di seluruh berkas test).

---

## Checklist Verifikasi Mandiri Codelab
- [x] UI tidak memanggil Dio langsung, semua akses data lewat repository + provider.
- [x] Empat state tampil benar: loading, error (+ retry), empty, success.
- [x] Pagination: data bertambah saat scroll, tidak ada request ganda, ada indikator akhir data.
- [x] `flutter analyze` tanpa issue (0 warning, 0 error).
- [x] Semua unit test dan mock repository test lulus (16/16 test).
- [x] Hasil AI Challenge diverifikasi dan didokumentasikan di folder `docs/`.

---

## Refleksi

### 1. Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?
- **Pemisahan Tanggung Jawab (*Separation of Concerns*):** Tugas utama widget UI adalah membangun representasi visual dan merespons interaksi pengguna. Mengatur URL, header, timeout, atau logika deserialisasi JSON di dalam UI melanggar prinsip arsitektur yang bersih.
- **Dampak Kerapuhan (*Tight Coupling* & *Low Testability*):** Jika UI terikat langsung ke `Dio`, pengujian widget terisolasi (*widget testing*) menjadi sangat sulit tanpa memicu HTTP request sungguhan ke jaringan luar. Dengan Repository Pattern, kita dapat dengan mudah mengganti dependensi repository menggunakan mock atau fake (`FakePostRepository`) via Riverpod overrides.
- **Duplikasi & Kompleksitas:** Jika format endpoint atau skema autentikasi backend berubah, developer harus mengubah banyak widget. Melalui repository, perubahan cukup dilakukan di satu tempat tanpa memengaruhi UI.

### 2. Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (`_page`/`_limit`)?
- **Client-Side Pagination Cukup:** Ketika total ukuran data kecil hingga menengah (kurang dari 100 data atau ukuran payload di bawah 1–2 MB), data cenderung statis, dan aplikasi memerlukan fitur pencarian, filter, atau penyortiran (*sorting*) instan di sisi lokal tanpa latensi bolak-balik ke server.
- **Server-Side Pagination Wajib Digunakan:** Ketika volume dataset sangat besar (ratusan hingga jutaan entri, misalnya feed media sosial atau katalog e-commerce), atau data bertambah secara dinamis. Pagination server menghemat kuota pengguna, meminimalkan penggunaan memori RAM perangkat, mempercepat waktu muat awal (*Time to Interactive*), serta mengoptimalkan kinerja database server melalui query `LIMIT` dan `OFFSET`.

### 3. Bagaimana exception repository berubah menjadi `AsyncError` tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?
- **Transformasi Deklaratif:** Pada Riverpod, method `build()` pada `AsyncNotifier` atau provider `FutureProvider` secara internal membungkus eksekusi fungsi dalam *guard*. Jika repository melempar error (*rethrow exception*), Riverpod secara otomatis menangkapnya dan mengubah state menjadi `AsyncError(error, stackTrace)`. UI cukup membaca state ini secara deklaratif melalui `.when(loading: ..., error: ..., data: ...)`.
- **Kebutuhan `try/catch` Eksplisit:** Tetap diperlukan pada **event callback pengguna** (misalnya saat tombol simpan ditekan, aksi mutasi data form, penghapusan item, atau method `refresh()`) di mana kegagalan perlu memicu aksi sampingan imperatif secara langsung seperti menampilkan `SnackBar`, dialog pesan, atau penanganan state rollback.

### 4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
- **Penyelarasan Sintaks Riverpod 3 Family:** Mengoreksi pembuatan Notifier family dari kelas lama ke arsitektur modern Riverpod 3 (`AsyncNotifierProvider.family` dengan constructor berparameter `CommentListNotifier(this.postId)`).
- **Casting Defensif pada Repositories:** Mengubah deserialisasi `whereType<Map<String, dynamic>>()` menjadi `data.whereType<Map>().map((e) => Comment.fromJson(Map<String, dynamic>.from(e)))` agar aman dari inkonsistensi tipe runtime map di platform Web.
- **Penambahan Edge Cases pada Testing:** Menambahkan skenario uji coba mandiri saat semua field bernilai `null` serta tipe numerik bertipe pecahan desimal (`10.0`), pemetaan status code 404/500, dan simulasi kegagalan jaringan pada provider.
- **Navigasi Anti-Crash (*Dual-Mode*):** Menambahkan blok *fallback* `Navigator.push` di `PostTile` sehingga jika aplikasi dijalankan tanpa context `GoRouter`, interaksi klik tetap membuka halaman detail secara mulus.

---

## Lampiran Dokumentasi & Screenshots

| Skenario | Screenshot |
|---|---|
| **Praktikum 2: Normal 100 Posts** | ![100 post](week4_api/screenshots/P2%20Provider%20dan%20error%20handling/100%20post.png) |
| **Praktikum 2: Error Handling (Timeout/Offline)** | ![timeout](week4_api/screenshots/P2%20Provider%20dan%20error%20handling/timeout.png) |
| **Praktikum 3: Pagination (Infinite Scroll)** | ![infinite scroll](week4_api/screenshots/P3%20Pagination%20dasar/infinite%20scroll.png) |
| **AI Challenge: Komentar Endpoint** | ![comment](week4_api/screenshots/AI%20Challenge/comment.png) |
| **AI Challenge: Testing** | ![comment](week4_api/screenshots/AI%20Challenge/testing.png) |

---

## Referensi Pendukung
- [Slide Minggu 4: Networking & REST API](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_04_Networking_REST_API.html)
- [Dio Package - pub.dev](https://pub.dev/packages/dio)
- [JSONPlaceholder (Free Fake REST API)](https://jsonplaceholder.typicode.com)
- [Riverpod: AsyncNotifier dan AsyncValue](https://riverpod.dev/docs/concepts/async_notifiers)
- [Flutter Cookbook: Fetch data from the internet](https://docs.flutter.dev/cookbook/networking/fetch-data)
- [Learn Dart in Y Minutes](https://learnxinyminutes.com/dart/)
