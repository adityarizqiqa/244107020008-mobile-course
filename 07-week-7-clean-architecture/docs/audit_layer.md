# Audit Layer & Verifikasi Dependensi (Praktikum 1 & Praktikum 3)

**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Minggu 7 - Clean Architecture  
**Mahasiswa:** Aditya Rizqiqa Ramadhan (NIM: 244107020008 / TI-3E)

---

## 1. Pemetaan File ke Layer (Sebelum vs Sesudah Refactor)

| File Lama | Layer Lama | Masalah Arsitektur (Sebelum Refactor) | Penataan Baru (Clean Architecture) | Layer Baru |
|---|---|---|---|---|
| `pages/notes_page.dart` | Presentation | Memanggil `sqflite` / DB secara tidak langsung via singleton, formatting tanggal di `build()`, dialog manipulasi query. | `features/notes/presentation/pages/notes_page.dart` | Presentation (Hanya me-watch Riverpod provider & formatting via `lib/core/format.dart`) |
| `data/local/note.dart` | Data + Domain (Tercampur) | Satu kelas merangkap Entity bisnis dan Model serialisasi (`toMap` dan `fromMap`). | Dipecah menjadi `domain/entities/note.dart` (murni) dan `data/models/note_model.dart` (serialisasi). | Domain & Data terpisah |
| `data/repositories/note_repository.dart` | Data + Domain (Tercampur) | Kontrak interface dan implementasi SQLite menyatu dalam 1 file; instansiasi DB di constructor. | Dipecah: `domain/repositories/note_repository.dart` (interface) dan `data/repositories/note_repository_impl.dart` (implementasi dengan `openDb` injected). | Domain (Interface) & Data (Impl) |
| `pages/announcement_page.dart` | Presentation | Parsing rute manual, formatting tanggal inline, data fetch tercampur. | `features/announcements/presentation/pages/announcements_page.dart` & `announcement_detail_page.dart`. | Presentation |
| `data/api_client.dart` | Data | Exception mentah dilempar langsung ke UI. | Ditransformasikan menjadi `Failure` (`NetworkFailure`, `NotFoundFailure`) di `AnnouncementRepositoryImpl`. | Data |

---

## 2. Pemeriksaan Tiga Pelanggaran Klasik

### Pelanggaran 1: Widget yang Menyentuh Jaringan / Database Langsung
- **Gejala Lama:** Pemanggilan `openDatabase`, `Dio(`, `FlutterSecureStorage`, atau `SharedPreferences.getInstance` langsung di dalam file widget.
- **Hasil Pemeriksaan di Folder Baru:**
  ```powershell
  Select-String -Pattern 'Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode' -Path 'lib/features/*/presentation/**/*.dart'
  ```
  **Output: 0 HASIL (Lolos / Steril 100%)**

### Pelanggaran 2: Logika Bisnis & Framework di Domain
- **Gejala Lama:** Mengimpor `package:flutter`, `package:dio`, `package:sqflite`, atau `package:firebase` di dalam domain atau core failure.
- **Hasil Pemeriksaan di Folder Baru:**
  ```powershell
  Select-String -Pattern "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" -Path @('lib/features/*/domain/**/*.dart', 'lib/core/**/*.dart')
  ```
  **Output: 0 HASIL (Lolos / Steril 100%)**

### Pelanggaran 3: Instansiasi Manual (DI Bocor) di Presentation
- **Gejala Lama:** Widget membuat instance repository secara manual (`new NoteRepository()`).
- **Hasil Pemeriksaan di Folder Baru:**
  ```powershell
  Select-String -Pattern 'Repository\(|Dio\(BaseOptions' -Path 'lib/features/*/presentation/pages/**/*.dart'
  ```
  **Output: 0 HASIL (Lolos / Steril 100%)**

---

## 3. Hasil Pengujian Otomatis

- **Static Analysis (`flutter analyze`):**
  ```text
  Analyzing 07-week-7-clean-architecture...
  No issues found! (ran in 4.5s)
  ```
- **Unit & Widget Test Suite (`flutter test`):**
  ```text
  00:07 +14: All tests passed!
  ```
  Seluruh 14 skenario pengujian use case, fake repository failure handling, format fungsi murni, dan app navigation smoke test lulus sempurna tanpa kegagalan.
