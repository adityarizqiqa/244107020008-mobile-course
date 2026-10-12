# Laporan AI Prompt Challenge & AI Verification Checklist

**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Minggu 7 - Clean Architecture & SOLID Principles  
**Mahasiswa:** Aditya Rizqiqa Ramadhan (NIM: 244107020008 / TI-3E)

---

## 1. Salinan Prompt Resmi AI Challenge

Berikut adalah prompt yang diberikan kepada AI Assistant sesuai dengan instruksi resmi modul codelab:

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Rangkuman Respon / Usulan Awal AI

AI coding assistant memberikan rekomendasi restrukturisasi sebagai berikut:
1. **Struktur Feature-First:** Membagi project menjadi `features/auth/` dan `features/announcements/`, masing-masing memiliki subfolder `domain/`, `data/`, dan `presentation/`.
2. **Pemetaan File Lama:**
   - `data/auth_repository.dart` dipecah menjadi `features/auth/domain/repositories/auth_repository.dart` (interface murni) dan `features/auth/data/repositories/auth_repository_impl.dart`.
   - `data/token_store.dart` dipindahkan ke `features/auth/data/datasources/token_store.dart`.
   - `pages/login_page.dart` dan `pages/announcement_page.dart` dipindahkan ke masing-masing folder `presentation/pages/`.
   - AI mengusulkan pembuatan kelas Use Case untuk setiap operasi (misal: `LoginWithCredentials`, `RefreshToken`, `GetAnnouncements`, `GetAnnouncementDetail`, `CheckAuthStatus`, `Logout`).
3. **Penyuntikan Dependensi (DI):** Disarankan menggunakan provider global Riverpod (`Provider<AuthRepository>`, dsb.) tanpa library injector eksternal seperti `get_it`.
4. **Catatan Over-engineering dari AI:** AI menyebutkan bahwa membungkus operasi satu baris seperti `getAnnouncements()` ke dalam Use Case terpisah bisa terasa berlebihan bila tidak ada logika validasi atau transformasi bisnis.

---

## 3. AI Verification Checklist & Evaluasi Kritis

Evaluasi mandiri dilakukan untuk menyaring usulan AI sebelum diadopsi:

| Pertanyaan Verifikasi | Hasil Evaluasi | Tindakan / Argumen Teknis |
|---|---|---|
| **Apakah interface repository tinggal di `domain` dan implementasi di `data`?** | **Lolos (Valid)** | Ya. AI menempatkan interface `AuthRepository` dan `AnnouncementRepository` di `domain/repositories/` dan implementasinya di `data/repositories/`. Tidak ada interface yang tercampur di `data`. |
| **Apakah `domain` bebas import Flutter/Dio/SQLite/Firebase?** | **Lolos (Valid)** | Diverifikasi dengan `rg`. Seluruh kelas di folder `domain/` murni Dart (`DateTime`, `String`, record ganda), tanpa dependensi framework. |
| **Apakah AI membuat use case untuk tiap CRUD satu-baris? (Over-engineering check)** | **Perlu Penyesuaian Kritis** | AI mengusulkan use case untuk seluruh operasi. Kami menilai: operasi yang murni delegasi satu-baris tanpa transformasi dapat langsung dipanggil dari Notifier ke Repository; use case dipertahankan pada operasi yang memiliki validasi bisnis (misal: `AddNote`, `GetAnnouncementDetail` dengan validasi parameter ID). |
| **Apakah entity bebas mapping (`toMap/fromMap/toJson` hanya di model)?** | **Lolos (Valid)** | Entity `Note` dan `Announcement` murni representasi bisnis tanpa fungsi serialisasi. Serialisasi JSON dan SQLite diisolasi penuh di `NoteModel` dan `AnnouncementModel`. |
| **Apakah wiring DI terpusat di provider dan widget tidak `new Repository()` sendiri?** | **Lolos (Valid)** | Seluruh wiring disatukan di file provider fitur masing-masing (`notes_providers.dart` dan `announcement_providers.dart`). Widget hanya memakai `ref.watch` dan `ref.read`. |

---

## 4. Tabel Perbandingan: Usulan AI vs Keputusan Final

| Aspek Arsitektur | Usulan Awal AI | Keputusan Final Kita | Alasan & Trade-Off Teknis |
|---|---|---|---|
| **Pemisahan Folder** | `features/{auth, announcements}` | `features/{notes, announcements}` | Menjaga kompatibilitas 100% dengan kode modul resmi (Fitur `notes` SQLite) sekaligus menyelesaikan Refactoring Challenge (Fitur `announcements`). |
| **Jumlah Use Case** | Membuat Use Case untuk semua operasi CRUD termasuk read satu baris. | Use Case dibuat dengan selektif: diwajibkan untuk yang memiliki validasi domain (`AddNote`, `UpdateNote`, `GetAnnouncementDetail`), sementara delegasi sederhana didukung via callable usecase. | Menghindari over-engineering dan ledakan file (*class explosion*) pada tim kecil, tetapi tetap mematuhi prinsip Clean Architecture bila logika bisnis berkembang. |
| **Komunikasi Antar Fitur** | Import page langsung dari fitur lain. | Navigasi decoupled via `routes.dart` (`go_router`) dan ShellRoute. | Menghilangkan kopling silang antar layer presentation fitur yang berbeda (*zero cross-feature presentation imports*). |
| **Penanganan Error** | Menggunakan exception umum Dart `Exception(e.toString())`. | Menggunakan `sealed class Failure` dengan return Dart Record ganda: `({T? data, Failure? failure})`. | Explicit failure handling mencegah crash tak terduga di UI, dan UI hanya menerima pesan ramah pengguna tanpa technical error leak. |
| **Date Formatting & Route Parsing** | Ditulis inline di dalam widget `build()`. | Diekstrak ke fungsi murni di `lib/core/format.dart`. | Memungkinkan unit test murni tanpa membutuhkan `WidgetTester` atau mock context. |

---

## 5. Ringkasan Kesimpulan AI Challenge

Penggunaan AI Coding Assistant sangat membantu dalam pemetaan cepat arsitektur dan pembuatan boilerplate kelas. Namun, verifikasi manusia tetap krusial untuk:
1. Memastikan **Dependency Rule** tidak dilanggar secara halus (misal: import Flutter di file entity).
2. Mengendalikan trade-off over-engineering agar tidak membebani pemeliharaan kode (*maintainability cost*).
3. Memastikan kontrak antarmuka (*interface contract*) menggunakan tipe data yang aman dan deterministik (Dart Records & Sealed Classes).
