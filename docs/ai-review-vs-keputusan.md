# Senior AI Code Review & Verification Matrix (Mid Project Review)

**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Codelab 08 - Mid Project Review & Code Review  
**Peran Evaluator:** Senior Flutter Architect & Lead Developer  
**Mahasiswa / Author:** Aditya Rizqiqa Ramadhan (NIM: 244107020008 / TI-3E)  
**Status Evaluasi:** Paruh Semester (Week 1 s.d. Week 8)  
**Arsitektur Standar:** Feature-first Clean Architecture (Presentation $\rightarrow$ Domain $\leftarrow$ Data)

---

## 🎯 1. Konteks & Standar Penilaian Arsitektur

Sebagai bagian dari *Mid Project Review*, dilakukan peninjauan mendalam (*in-depth code review*) terhadap implementasi arsitektur perangkat lunak pada repository ini. Evaluasi difokuskan pada kepatuhan terhadap prinsip arsitektur perangkat lunak modern:
1. **The Dependency Rule (Clean Architecture):** Domain layer merupakan inti murni bisnis yang tidak boleh mengenal detail UI (Flutter SDK), jaringan (Dio/HTTP), database lokal (SQLite), atau package pihak ketiga.
2. **Keterpisahan Peran (Separation of Concerns):** Entitas murni (`Entity`) terisolasi dari serialisasi data (`Model`), kontrak didefinisikan lewat interface repository di `domain/repositories/`, dan diimplementasikan di `data/repositories/`.
3. **Penyuntikan Dependensi (Dependency Injection):** Seluruh kabel dependensi dialirkan via Riverpod provider tanpa instansiasi manual (`new`) di presentation layer.
4. **Verifikasi Mesin (Automated Quality Gates):** Kode wajib lolos linter analitik (`flutter analyze`), standar pemformatan (`dart format`), dan seluruh suite pengujian otomatis (`flutter test`).

---

## 🔍 2. Simulasi Senior AI Code Review (5 Temuan Teratas)

Berikut adalah 5 temuan teratas yang diidentifikasi oleh simulasi AI Code Reviewer terhadap codebase saat ini:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                   HASIL SCANNING SENIOR AI CODE REVIEWER                        │
├────┬──────────┬────────────────────────────────────────┬────────────────────────┤
│ No │ Severity │ Kategori                               │ Lokasi Berkas          │
├────┼──────────┼────────────────────────────────────────┼────────────────────────┤
│ 1  │ Blocker  │ Domain Logic & Boundary Validation     │ notes/domain/usecases/ │
│ 2  │ Blocker  │ Automated CI Gate (Code Formatting)   │ lib/ & test/           │
│ 3  │ Saran    │ Domain Purity vs Framework Import      │ domain/entities/       │
│ 4  │ Saran    │ Tooling & Code Generation Overhead     │ domain/ & data/        │
│ 5  │ Saran    │ Lifecycle Safety & Memory Leak         │ notes/presentation/    │
└────┴──────────┴────────────────────────────────────────┴────────────────────────┘
```

---

### Temuan 1: [Blocker] Validasi Batas ID Non-Positif pada Use Case Domain `UpdateNote` dan `DeleteNote`
* **File Terkait:** `lib/features/notes/domain/usecases/update_note.dart` & `delete_note.dart`
* **Alasan Teknis AI:**
  Pada fitur `announcements`, use case `GetAnnouncementDetail` menerapkan validasi bisnis domain secara disiplin:
  ```dart
  if (id <= 0) {
    return Future.value((
      announcement: null,
      failure: const ValidationFailure('ID pengumuman tidak valid.'),
    ));
  }
  ```
  Sebaliknya, pada use case `UpdateNote` dan `DeleteNote`, parameter `id` langsung diteruskan ke interface repository tanpa validasi nilai batas (`id <= 0`). Bila input invalid dikirimkan dari UI atau deep link, sistem akan menjalankan kueri SQLite sia-sia (`UPDATE notes WHERE id = -1` atau `DELETE FROM notes WHERE id = -1`) sebelum menyadari entitas tidak ada. Validasi integritas identitas bisnis adalah tanggung jawab mutlak layer Domain.

* **Potongan Kode Perbaikan (Code Proposal):**
  ```dart
  // lib/features/notes/domain/usecases/delete_note.dart
  import '../../../../core/failures.dart';
  import '../repositories/note_repository.dart';

  class DeleteNote {
    const DeleteNote(this._repository);
    final NoteRepository _repository;

    Future<({bool success, Failure? failure})> call(int id) {
      if (id <= 0) {
        return Future.value((
          success: false,
          failure: const ValidationFailure('ID catatan tidak valid.'),
        ));
      }
      return _repository.deleteNote(id);
    }
  }
  ```

---

### Temuan 2: [Blocker] Pelanggaran Standar Format Kode Dart pada Pipeline CI (`dart format`)
* **File Terkait:** 18 Berkas di direktori `lib/` dan `test/`
* **Alasan Teknis AI:**
  Saat dilakukan pemeriksaan otomatis via perintah:
  ```bash
  dart format --output=none --set-exit-if-changed .
  ```
  Proses berhenti dengan **Exit Code 1** dan menandai 18 berkas dengan indentasi/pemecahan baris yang tidak sesuai dengan *Dart Style Guide*. Pada pipeline GitHub CI yang mensyaratkan `dart format --set-exit-if-changed .`, seluruh PR otomatis akan berstatus **FAILED (Red Build)** dan memblokir proses integrasi cabang.

* **Potongan Kode Perbaikan (Code Proposal):**
  Jalankan pemformatan menyeluruh dan pasang pre-commit hook otomatis:
  ```bash
  dart format .
  ```

---

### Temuan 3: [Saran] Penambahan Anotasi `@immutable` dari `package:flutter/foundation.dart` pada Entity
* **File Terkait:** `lib/features/notes/domain/entities/note.dart` & `lib/features/announcements/domain/entities/announcement.dart`
* **Alasan Teknis AI:**
  AI menyarankan menambahkan anotasi `@immutable` pada kelas Entity untuk memastikan objek tidak dimutasi sembarangan setelah diinstansiasi.
* **Potongan Kode Rekomendasi AI (AI Proposal):**
  ```dart
  // lib/features/notes/domain/entities/note.dart
  import 'package:flutter/foundation.dart'; // <-- DIUSULKAN OLEH AI

  @immutable
  class Note {
    const Note({
      this.id,
      required this.title,
      required this.body,
      required this.updatedAt,
      this.dirty = false,
    });
    ...
  }
  ```

---

### Temuan 4: [Saran] Migrasi Seluruh Entity & Model ke Code Generation `freezed` + `build_runner`
* **File Terkait:** Seluruh berkas Entity di `domain/entities/` dan Model di `data/models/`
* **Alasan Teknis AI:**
  AI menyarankan mengadopsi library `freezed` dan `json_serializable` untuk mengotomatiskan pembuatan method `copyWith`, pembanding nilai (`==` dan `hashCode`), serta serialisasi JSON, sehingga kode menjadi lebih deklaratif.
* **Potongan Kode Rekomendasi AI (AI Proposal):**
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  part 'note.freezed.dart';

  @freezed
  class Note with _$Note {
    const factory Note({
      int? id,
      required String title,
      required String body,
      required DateTime updatedAt,
      @Default(false) bool dirty,
    }) = _Note;
  }
  ```

---

### Temuan 5: [Saran] Potensi Resource Leak pada `TextEditingController` & Unchecked Async Gap di `NotesPage`
* **File Terkait:** `lib/features/notes/presentation/pages/notes_page.dart` (baris 216–290)
* **Alasan Teknis AI:**
  1. Pada method `_showNoteDialog`, `TextEditingController` diinstansiasi secara lokal di dalam fungsi tanpa siklus hidup `.dispose()`. Jika pengguna sering membuka dan menutup dialog, instans controller ini akan terakumulasi di memori.
  2. Pemanggilan `Navigator.of(dialogCtx).pop()` dan `ScaffoldMessenger.of(context).showSnackBar()` dieksekusi setelah jeda `await` Use Case asynchronous tanpa pengecekan status `if (!context.mounted) return;`. Jika widget telah di-unmount saat operasi async berjalan, hal ini dapat memicu error runtime *Flutter framework assertion*.

* **Potongan Kode Perbaikan (Code Proposal):**
  ```dart
  // Menambahkan pengecekan context.mounted pasca-await
  final result = await ref.read(updateNoteUseCaseProvider).call(
    id: note.id!,
    title: titleController.text,
    body: bodyController.text,
  );

  if (!context.mounted) return; // <-- Guard clause async gap

  if (result.failure != null) {
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(result.failure!.message)),
    );
  } else {
    nav.pop();
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }
  ```

---

## ⚖️ 3. Tabel Keputusan Verifikasi Lead Developer

Sebagai Lead Developer, tidak semua usulan AI dapat diterima mentah-mentah. Setiap rekomendasi disaring melalui lensa arsitektur, beban pemeliharaan (*maintenance overhead*), dan aturan dependensi proyek.

| No | Temuan AI | Severity | Keputusan Lead Developer | Klasifikasi Bukti / Alasan Teknis Penolakan |
|---|---|---|---|---|
| **1** | Validasi ID non-positif pada `UpdateNote` & `DeleteNote` | **Blocker** | **DITERIMA (BENAR)** | **Bukti Reproduksi Logic & Unit Test:** Saat diuji dengan unit test `DeleteNote(-5)`, tanpa validasi domain usecase meloloskan query ke repository. Dengan penambahan guard clause domain, sistem mengembalikan `ValidationFailure` secara deterministik tanpa menyentuh data layer. |
| **2** | Standar format kode gagal pada CI (`dart format`) | **Blocker** | **DITERIMA (BENAR)** | **Bukti Terminal/CLI:** Eksekusi `dart format --output=none --set-exit-if-changed .` menghasilkan Exit Code 1 pada 18 berkas. Ini adalah *hard gate* di CI yang wajib diselesaikan sebelum PR dapat di-merge. |
| **3** | Import `package:flutter/foundation.dart` untuk anotasi `@immutable` di Entity | **Saran** | **DITOLAK (REJECTED)** | **Alasan Pelanggaran Dependensi (The Dependency Rule):** Usulan AI melanggar aturan mutlak Clean Architecture: *Domain layer tidak boleh mengimpor Flutter*. Immutability sudah dijamin oleh `const constructor` dan field `final`. Jika anotasi static analyzer tetap diinginkan, gunakan `package:meta/meta.dart` (murni Dart) tanpa mencemari domain dengan runtime framework Flutter. |
| **4** | Migrasi Entity & Model ke `freezed` + `build_runner` | **Saran** | **DITOLAK (REJECTED)** | **Alasan Over-Engineering & CI Overhead:** Membutuhkan `dart run build_runner build` di setiap build CI, menambah runtime dependency pada domain, serta memperlambat siklus kompilasi. Fitur Dart 3 modern (*Records*, *Pattern Matching*, dan *Sealed Classes*) telah mencukupi kebutuhan tanpa beban code generation eksternal. |
| **5** | Potensi Resource Leak Controller & Unchecked Async Gap | **Saran** | **DITERIMA (BENAR)** | **Bukti Grep & Audit Kode:** Audit baris 216–290 di `notes_page.dart` membuktikan controller tidak di-dispose dan context diakses pasca-await tanpa guard `if (!context.mounted) return;`. |

---

## 🛡️ 4. Rangkuman Tanggung Jawab Teknis Lead Developer

Dalam ekosistem rekayasa perangkat lunak modern yang didukung kecerdasan buatan (AI-Assisted Development), peran seorang **Lead Developer & Software Architect** mengalami pergeseran paradigma dari sekadar penulis kode menjadi **penjaga gerbang integritas sistem (System Integrity Gatekeeper)**:

### 1. Menjaga Batas Arsitektural (Architectural Boundary Enforcement)
AI cenderung mengoptimalkan penyelesaian masalah secara lokal tanpa memahami konteks arsitektur makro. Sebagai contoh pada Temuan 3, AI mengusulkan `@immutable` dengan mengimpor `package:flutter/foundation.dart` ke dalam domain entity. Bagi linter biasa hal ini terlihat benar, tetapi bagi seorang Architect, ini adalah pelanggaran fatal terhadap prinsip *Inversion of Control* dan *Transitive Dependency Isolation*. Lead Developer wajib menjaga agar layer domain tetap murni 100% Dart.

### 2. Mengendalikan Kompleksitas & Over-Engineering
AI sering menyarankan library populer (seperti `freezed`, `bloc`, atau code generator rumit) untuk masalah sederhana. Lead Developer bertanggung jawab menentukan *trade-off*: apakah keuntungan sebuah package sebanding dengan beban dependensi, waktu build di CI, dan *learning curve* tim. Keputusan menolak `freezed` (Temuan 4) dan memilih fitur murni *Dart 3 Records* adalah contoh mitigasi kompleksitas yang disengaja.

### 3. Membangun Automated Quality Gates yang Tidak Dapat Dinegosiasikan
Disiplin tim ditegakkan melalui sistem, bukan asumsi. Lead Developer merancang workflow CI GitHub Actions yang mengunci tiga pilar verifikasi:
- Linter dan *zero-warning policy* (`flutter analyze`).
- Konsistensi gaya penulisan kode (`dart format`).
- Keberhasilan seluruh rangkaian pengujian unit dan widget (`flutter test`).

### 4. Mentransformasikan Hasil AI Review Menjadi Tindakan Nyata
Lead Developer memvalidasi temuan kritis AI (seperti validasi domain pada Temuan 1 dan lifecycle safety pada Temuan 5), membuktikannya melalui unit test, dan mengintegrasikan perbaikannya ke dalam PR sebelum kode mencapai cabang produksi (`main`).

