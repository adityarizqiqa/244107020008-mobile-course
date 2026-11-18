# AI-Assisted Development Log (Minggu 9: Vibe Coding & Code Verification)

**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Minggu 9 - AI-Assisted Development / Vibe Coding  
**Fitur:** Real-time Note Search by Title dengan Feature-First Clean Architecture & Riverpod 3.x  
**Author:** Aditya Rizqiqa Ramadhan (NIM: 244107020008 / TI-3E)

---

## 1. Spesifikasi Tugas & Perintah (Prompt)

Menambahkan fitur pencarian (*search*) catatan berdasarkan judul (`title`) secara real-time pada `notes_page.dart` dengan kriteria:
1. **Domain Isolation:** Membuat pure use case `SearchNotes` di `lib/features/notes/domain/usecases/search_notes.dart` tanpa import Flutter, SQLite, atau Dio.
2. **Business Rule:** Filter bersifat *case-insensitive*, mengabaikan spasi berlebih (`trim()`), dan mengembalikan seluruh daftar catatan jika query kosong.
3. **Presentation & State Management:** Mengintegrasikan `searchQueryProvider` (`NotifierProvider`) dan `filteredNotesProvider` pada `notes_providers.dart` untuk konsumsi UI di `notes_page.dart`.
4. **Clean Code & Constraint:** Setiap fungsi maksimal 40 baris, setiap berkas baru maksimal 80 baris.
5. **Testing Suite:** Melengkapi dengan unit test (`test/search_notes_test.dart`) dan widget test (`test/notes_search_widget_test.dart`).

---

## 2. Refleksi & Penyesuaian Kritis (Human-in-the-Loop Verification)

| Masalah / Temuan Awal AI | Analisis Teknis | Keputusan & Perbaikan Arsitektural |
|---|---|---|
| **Penggunaan `StateProvider` di Riverpod 3.x** | Paket `flutter_riverpod: ^3.4.3` telah menghapus/mendepresiasi `StateProvider`, memicu error kompilasi analitik. | Mengadopsi kelas murni `SearchQueryNotifier extends Notifier<String>` yang di-wire melalui `NotifierProvider` resmi Riverpod 3.x. |
| **Pemisahan Logika Filter di Domain** | Menghindari filtering ad-hoc di widget `build()` atau kueri ulang database SQLite pada setiap keystroke. | Mengekstraksi fungsi filter ke dalam Use Case murni `SearchNotes` yang memproses daftar `List<Note>` di memori secara sinkron dan instan. |
| **Batas Ukuran Method (< 40 baris)** | Metode rendering empty state awalnya mencakup dua percabangan sekaligus sehingga melebihi 40 baris. | Memecah UI menjadi `_buildEmptyState`, `_buildSearchEmptyState`, dan `_buildInitialEmptyState` (masing-masing < 35 baris). |

---

## 3. Hasil Verifikasi Mesin (Quality Gates)

1. **Format Kode (`dart format`):**
   ```text
   Formatted 32 files (0 changed) in 0.10 seconds.
   ```
2. **Analisis Statis (`flutter analyze`):**
   ```text
   Analyzing 09-week-9-ai-assisted-development...
   No issues found! (ran in 5.6s)
   ```
3. **Pengujian Otomatis (`flutter test`):**
   ```text
   24/24 tests passed (100% Green).
   ```

