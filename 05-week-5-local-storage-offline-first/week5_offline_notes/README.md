# Week 5 Offline Notes

Aplikasi Flutter berbasis **Offline-First** dengan arsitektur Repository Pattern, Riverpod State Management, SharedPreferences, dan SQLite (`sqflite`).

## Fitur Utama
1. **Penyimpanan Preferensi (SharedPreferences):**
   - Toggle Tema Terang / Gelap yang persisten.
   - Pencatatan waktu terakhir aplikasi dibuka (`last_opened_at`).
2. **Offline Notes CRUD (SQLite):**
   - Tambah, lihat, ubah, dan hapus catatan secara lokal tanpa ketergantungan internet.
   - Status antrean sinkronisasi (`dirty` flag) pada setiap catatan.
3. **Pola Cache-First API (JSONPlaceholder Posts):**
   - Data dibaca seketika dari tabel SQLite `cached_posts`.
   - Latar belakang (background) memperbarui cache melalui HTTP `/posts`.
4. **Antrean Sinkronisasi & Simulasi Offline:**
   - Fitur toggle deterministik `forceOffline` untuk simulasi offline.
   - Aksi sinkronisasi manual yang mengubah catatan kotor (`dirty = 1`) menjadi bersih (`dirty = 0`).
   - Resolusi konflik *Last-Write-Wins (LWW)* berbasis `updated_at`.
5. **Unit & Widget Testing:**
   - Seluruh unit test model, serialisasi, dan provider dengan repositori tiruan (`FakeNoteRepository`) lulus 100%.

## Testing & Analisis
```bash
flutter analyze
flutter test
```
