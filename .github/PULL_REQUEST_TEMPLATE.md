## 📌 Format Judul Pull Request (Conventional Commits)
<!--
Gunakan konvensi penamaan commit standar industri:
<type>(<scope>): <deskripsi singkat imperative>

Contoh yang valid:
- feat(notes): validasi judul kosong + test
- fix(announcements): perbaiki parsing id rute deep link
- refactor(core): ekstraksi fungsi murni format tanggal
- test(usecase): tambahkan unit test kegagalan jaringan
- docs(review): lengkapi checklist audit paruh semester
-->

**Judul PR:** `type(scope): deskripsi singkat`

---

## 🎯 1. Deskripsi Masalah & Kebutuhan Fitur
<!-- Jelaskan latar belakang perubahan, bug yang dialami, atau fitur baru yang ditambahkan -->
### Masalah / Kebutuhan:
- 

### Solusi Arsitektural:
- 

---

## 🏛️ 2. Kepatuhan Clean Architecture & SOLID Principles
<!-- Tandai checklist prinsip arsitektur yang dipenuhi dalam PR ini -->
- [ ] **The Dependency Rule:** Layer Domain 100% murni Dart (tidak mengimpor `package:flutter`, `dio`, `sqflite`, atau packages eksternal).
- [ ] **Separation of Concerns:** Entity bisnis dipisahkan secara murni dari Model serialisasi (`toMap` / `fromMap` / `toJson`).
- [ ] **Interface Segregation:** Kontrak Repository didefinisikan secara modular di `domain/repositories/` dan diimplementasikan di `data/repositories/`.
- [ ] **Dependency Injection:** Penyuntikan dependensi dikelola terpusat via Riverpod Provider (`ref.watch` / `ref.read`), tidak ada instansiasi manual (`new Repository()`) di layer UI.
- [ ] **Predictable Error Handling:** Pengembalian data menggunakan Dart 3 Record ganda `({T? data, Failure? failure})` atau `sealed class Failure`.

---

## 🧪 3. Cara Pengujian (Testing Steps)
<!-- Tuliskan panduan langkah demi langkah bagi reviewer untuk memverifikasi perubahan ini -->

### Pengujian Otomatis (CLI):
```bash
# Pindah ke direktori project
cd 07-week-7-clean-architecture

# 1. Jalankan linter & static analysis
flutter analyze

# 2. Periksa standard pemformatan kode
dart format --output=none --set-exit-if-changed .

# 3. Jalankan suite unit & widget testing
flutter test
```

### Pengujian Manual / Skenario Verifikasi:
1. Jalankan aplikasi pada simulator / perangkat / Chrome: `flutter run -d chrome`.
2. Buka halaman ...
3. Lakukan aksi ...
4. Verifikasi bahwa perilaku yang diharapkan muncul sesuai spesifikasi.

---

## 🤖 4. Checklist Verifikasi Mesin (Quality Gates)
<!-- Wajib dicentang seluruhnya sebelum meminta approval dan merge -->
- [ ] `flutter analyze` bersih (0 issues, 0 warnings, 0 errors).
- [ ] `dart format --output=none --set-exit-if-changed .` lolos tanpa perubahan format yang tertinggal.
- [ ] `flutter test` seluruh skenario pengujian lulus (100% test green).
- [ ] Tidak ada breaking change yang merusak dependensi layer lain.

---

## 🔗 5. Tautan Issue Terkait
<!-- Hubungkan PR ini dengan issue backlog yang diselesaikan -->
- Closes #
- Relates to #

