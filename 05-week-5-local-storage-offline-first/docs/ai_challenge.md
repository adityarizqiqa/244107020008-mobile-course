# Dokumentasi AI Challenge: Local Storage & Offline-First

Dokumen ini disusun untuk memenuhi tugas **AI Challenge** pada modul praktikum [Codelab Minggu 5 Polinema](https://jti-polinema.github.io/flutter-codelab/05-minggu-5-local-storage-offline-first/index.html#5).

---

## 1. AI Prompt Challenge (Prompt yang Digunakan)

Prompt berikut diajukan kepada AI Coding Assistant sesuai instruksi resmi modul:

```text
Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift
untuk dua kebutuhan ini. Requirements:
- Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream),
  type-safety, ukuran boilerplate, dan kemudahan testing.
- Beri rekomendasi final: mana untuk preferensi, mana untuk catatan,
  beserta alasannya dalam 1 tabel.
- Tunjukkan skema tabel/kotak untuk 1000+ catatan.
Jelaskan trade-off setiap pilihan.
```

---

## 2. Output Awal AI (Analisis & Rekomendasi)

### A. Perbandingan 4 Teknologi Penyimpanan

| Kriteria Evaluasi | SharedPreferences | Hive | sqflite (SQLite) | Drift (Moor) |
|---|---|---|---|---|
| **Kompleksitas Query** | Sangat Rendah (Key-value lookup saja) | Rendah–Sedang (Query manual via filter iterasi list/box) | Tinggi (Full SQL: WHERE, ORDER BY, GROUP BY, subquery) | Sangat Tinggi (Type-safe fluent Dart query builder + SQL) |
| **Kebutuhan Relasi** | Tidak Ada (Hanya data primitif skalar) | Tidak Ada (Relasi antar box manual/rapuh) | Kuat (Foreign keys, JOIN multi-tabel, integrity check) | Sangat Kuat (Relasi deklaratif Dart class / SQL) |
| **Reaktivitas (Stream)** | Tidak Ada | Ada (Mendukung `box.watch()`) | Tidak Ada bawaan (Memerlukan polling/Riverpod invalidation) | Kuat (Stream query reaktif bawaan via `watch()`) |
| **Type-Safety** | Rendah (Type casting manual `as bool?`) | Sedang (Membutuhkan register `TypeAdapter`) | Rendah (Berbasis dynamic `Map<String, Object?>`) | Sangat Tinggi (Compile-time type check via code generator) |
| **Ukuran Boilerplate** | Sangat Kecil (Langsung get/set) | Sedang (Registrasi adapter, openBox) | Sedang (Skema query string, migration helper) | Besar (`build_runner`, file `.g.dart`, anotasi skema) |
| **Kemudahan Testing** | Sangat Mudah (`setMockInitialValues`) | Mudah (Mock in-memory box) | Sangat Mudah (Dependency injection `openDb`) | Mudah (In-memory `NativeDatabase.memory()`) |

### B. Trade-Off Setiap Pilihan
* **SharedPreferences:** Sangat efisien untuk pengaturan kecil, namun berbahaya jika dipaksa menyimpan array JSON catatan karena setiap modifikasi 1 item mengharuskan deserialisasi dan penulisan ulang seluruh file XML/Plist.
* **Hive:** Sangat cepat untuk operasi baca/tulis objek tanpa SQL parser, namun tidak memiliki SQL indexing mutakhir dan rentan fragmentasi memori pada dataset catatan yang sering di-update/delete.
* **sqflite (SQLite):** Standar industri paling stabil dan matang di Android/iOS. Tidak memerlukan proses build generator yang lambat, namun query berbasis string rawan typo pada nama kolom jika tidak dibungkus model dengan rapi.
* **Drift:** Menawarkan pengalaman type-safe terbaik dengan reactive stream query, namun memiliki beban build time dan dependensi tooling yang cukup berat untuk aplikasi catatan skala kecil–menengah.

### C. Rekomendasi Alokasi Kebutuhan

| Kebutuhan Aplikasi | Rekomendasi Teknologi | Alasan Utama |
|---|---|---|
| **Preferensi Tema (`dark_mode`) & Waktu Buka** | `SharedPreferences` | Akses instan untuk nilai tunggal boolean/string tanpa overhead inisialisasi database engine. |
| **Koleksi Catatan (Offline Notes CRUD + Sync)** | `SQLite (sqflite)` | Mendukung filter antrean `WHERE dirty = 1`, pengurutan `ORDER BY updated_at DESC`, dan integritas transaksi ACID saat sinkronisasi batch. |

### D. Skema Database untuk 1000+ Catatan

```sql
-- Tabel Catatan Offline dengan Indeks Performa Tinggi
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);

-- Indeks untuk mempercepat antrean sinkronisasi
CREATE INDEX idx_notes_dirty ON notes (dirty);

-- Indeks untuk pengurutan linimasa catatan terbaru
CREATE INDEX idx_notes_updated_at ON notes (updated_at DESC);

-- Tabel Cache Respons Jaringan (Cache-First Read)
CREATE TABLE cached_posts (
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL
);
```

---

## 3. AI Verification Checklist (Verifikasi & Temuan Mahasiswa)

Sebelum rekomendasi AI diterima ke dalam arsitektur proyek, berikut adalah hasil evaluasi kritis terhadap rekomendasi yang dihasilkan:

- [x] **Apakah AI menempatkan daftar catatan di SharedPreferences?**  
  **Hasil Verifikasi: DITOLAK.**  
  AI telah merekomendasikan SQLite untuk daftar catatan dan SharedPreferences hanya untuk preferensi. Menempatkan koleksi catatan dalam satu string JSON di SharedPreferences adalah anti-pattern karena membatalkan kemampuan partial updates, pengurutan terindeks, dan sangat rawan korupsi data saat mutasi serentak.

- [x] **Apakah skema AI mendukung antrean sync (dirty flag / updated_at) atau hanya CRUD polos?**  
  **Hasil Verifikasi: VALID.**  
  Skema tabel `notes` yang diusulkan telah menyertakan kolom `dirty INTEGER NOT NULL DEFAULT 0` dan `updated_at TEXT NOT NULL`. Kolom ini menjadi fondasi utama dalam mekanisme *dirty queue* dan penyelesaian konflik *Last-Write-Wins (LWW)*.

- [x] **Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?**  
  **Hasil Verifikasi: DIVERIFIKASI.**  
  Klaim reaktivitas native benar hanya ada pada Drift (`select().watch()`) dan Hive (`box.watch()`). Pada `sqflite`, pembaruan UI "real-time" dilakukan melalui integrasi Riverpod provider (`ref.invalidate(notesProvider)`) setiap kali terjadi mutasi data di repository.

- [x] **Apakah estimasi boilerplate AI masuk akal setelah mencoba instalasinya?**  
  **Hasil Verifikasi: DIVERIFIKASI.**  
  Estimasi boilerplate AI akurat. Penggunaan Drift memerlukan instalasi dependensi ganda (`drift`, `drift_dev`, `build_runner`) yang memperlambat kompilasi awal. Kombinasi `sqflite` + `shared_preferences` jauh lebih ringan dan langsung siap pakai tanpa proses *code generation*.

- [x] **Keputusan final dan justifikasi teknis:**  
  **Keputusan:** Menyetujui dan menerapkan kombinasi **`SharedPreferences`** untuk pengaturan preferensi serta **`SQLite (sqflite)`** untuk koleksi catatan offline dan antrean sinkronisasi.
