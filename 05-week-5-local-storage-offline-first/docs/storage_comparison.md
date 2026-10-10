# Perbandingan Local Storage & Offline-First Strategy (Minggu 5)

## 1. Analisis & Perbandingan Local Storage di Flutter

Dalam pengembangan aplikasi Flutter, pemilihan mekanisme penyimpanan lokal (local storage) harus disesuaikan dengan jenis data, kompleksitas query, serta kebutuhan sinkronisasi offline-first.

| Kriteria | SharedPreferences | Hive | SQLite (`sqflite`) | Drift (Moor) |
|---|---|---|---|---|
| **Jenis Penyimpanan** | Key-Value (Primitif) | NoSQL Key-Value / Box | Relasional (SQL Engine) | Relasional (Type-safe SQL & reactive) |
| **Kompleksitas Query** | Sangat rendah (hanya get/set key) | Rendah–Menengah (filter via iterasi/indeks manual) | Tinggi (Full SQL syntax, JOIN, WHERE, ORDER BY, agregasi) | Sangat tinggi (Query builder Dart type-safe + SQL mentah) |
| **Kebutuhan Relasi** | Tidak mendukung | Tidak mendukung relasi alami antar box | Mendukung penuh foreign key & relasi multi-tabel | Mendukung relasi deklaratif kuat via class Dart |
| **Reaktivitas (Stream)** | Tidak ada secara native | Mendukung watch value/box | Manual polling / diatur via provider state management | Reaktif bawaan (`watch()` mengembalikan Stream query) |
| **Type-Safety** | Lemah (hanya type casting manual) | Menengah (TypeAdapters) | Rendah (Map dynamic `Map<String, Object?>`) | Sangat tinggi (Code generation, query type-safe compile-time) |
| **Boilerplate & Setup** | Hampir tanpa boilerplate | Sedang (register adapter & box open) | Sedang (skema SQL string, helper query) | Cukup besar (`build_runner`, file generator, skema tabel Dart) |
| **Kemudahan Testing** | Sangat mudah (`setMockInitialValues`) | Mudah (mock box / in-memory) | Sangat mudah via dependency injection `openDb` | Mudah (in-memory database `NativeDatabase.memory()`) |

---

## 2. Keputusan Final Pemilihan Storage

1. **Pengaturan Aplikasi (Tema & Riwayat Terakhir Dibuka) -> `SharedPreferences`**
   - **Alasan:** Data berupa nilai primitif skalar (`bool dark_mode` dan `String last_opened_at`). Tidak membutuhkan query relasional atau indexing, akses sangat cepat dan ringan.

2. **Koleksi Catatan & Antrean Sinkronisasi (Offline Notes) -> SQLite (`sqflite`)**
   - **Alasan:**
     - Koleksi catatan membutuhkan pengurutan dinamis (`ORDER BY updated_at DESC`).
     - Membutuhkan pemfilteran query untuk antrean sync (`WHERE dirty = 1`).
     - Menyimpan catatan dalam bentuk JSON string tunggal di SharedPreferences akan lambat, rawan korupsi data saat mutasi parsial, dan sulit dilakukan agregasi count (`countDirty`).
     - `sqflite` tidak memerlukan code generator tambahan yang memperberat dependensi build, namun tetap stabil dan andal di level native Android/iOS.

3. **Cache Respons API (Cache-First Read) -> SQLite Table `cached_posts`**
   - **Alasan:** Respons API disimpan dengan primary key `id`, `payload` (JSON text), dan `cached_at`. Memungkinkan penghapusan, penggantian atomik via `replace`, dan pembacaan offline instan.

---

## 3. Skema Database SQLite (1000+ Catatan)

Untuk mendukung performa tinggi pada skala ribuan catatan:
```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
);

-- Indeks untuk mempercepat antrean sync dan pengurutan daftar catatan
CREATE INDEX idx_notes_dirty ON notes (dirty);
CREATE INDEX idx_notes_updated_at ON notes (updated_at DESC);

-- Tabel cache data jaringan
CREATE TABLE cached_posts (
  id INTEGER PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL
);
```

---

## 4. Mekanisme Offline-First & Resolusi Konflik

### A. Cache-First Read
1. Aplikasi segera memuat data dari tabel lokal SQLite (`cached_posts`) agar UI langsung menampilkan konten tanpa blank screen atau loading spinner berlebih.
2. Di background (bila tidak dalam simulasi offline), aplikasi melakukan request HTTP ke endpoint `/posts`.
3. Bila respons berhasil, data cache SQLite diperbarui (`replace`), dan state provider diperbarui secara mulus.

### B. Antrean Sinkronisasi Catatan (Dirty Flag)
1. Setiap operasi `addNote` atau `updateNote` secara otomatis menyetel flag `dirty = 1` dan `updated_at = DateTime.now()`.
2. Antrean sync dihitung via `countDirty()`.
3. Saat fungsi `syncNotes` dijalankan:
   - Jika koneksi tersedia dan dirty > 0, perubahan dikirim ke server.
   - Setelah server mengonfirmasi (simulasi 200 OK), data ditandai bersih (`dirty = 0`).

### C. Aturan Resolusi Konflik
- **Strategi:** *Last-Write-Wins (LWW)* berdasarkan timestamp `updated_at`.
- Bila terjadi perselisihan data antara server dan perangkat klien, catatan dengan `updated_at` paling baru yang akan dipertahankan.
