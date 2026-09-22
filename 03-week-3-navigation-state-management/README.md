# Week 3: Navigation & State Management

Nama: Aditya Rizqiqa Ramadhan  
NIM: 244107020008  
Kelas: TI-3E (Teknologi Informasi, Politeknik Negeri Malang)  

## Tujuan
Proyek ini dibangun untuk memahami dan mengimplementasikan arsitektur navigasi modern menggunakan `go_router` dan manajemen state yang reaktif menggunakan `flutter_riverpod`.

## Fitur Utama
* **Manajemen ToDo:** Menambah, menyelesaikan (mencoret), dan menghapus daftar tugas dengan state yang dikelola oleh `Notifier`.
* **Statistik Asinkron:** Halaman statistik yang menyimulasikan pemanggilan jaringan (delay 2 detik) dengan probabilitas *error* 30%, dikelola menggunakan `AsyncNotifier`.
* **Navigasi Statis:** Penggunaan `ShellRoute` pada GoRouter untuk mempertahankan `NavigationBar` di bagian bawah saat berpindah halaman.
* **UI Responsif:** Menangani tiga kondisi state asinkron (Loading, Error, Success) secara presisi menggunakan `AsyncValue`.

## Stack Teknologi
* Framework: Flutter (Dart)
* State Management: `flutter_riverpod` (v2.x)
* Navigation: `go_router`
* Pengujian: `flutter_test`

## Cara Menjalankan
1. Pastikan Flutter SDK sudah terpasang.
2. Jalankan perintah `flutter pub get` di terminal untuk mengunduh dependencies.
3. Jalankan aplikasi menggunakan perintah `flutter run`.
4. Untuk menjalankan pengujian, jalankan perintah `flutter test`.

## Hasil Verifikasi AI (AI Challenge)
**1. Apakah state diubah secara immutable?** Ya, pembaruan data mengembalikan *list* baru.
**2. Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?** Ya.
**3. Apakah ketiga state AsyncValue ditangani?** Ya, ter-handle secara menyeluruh menggunakan `when`.
**4. Apakah provider dideklarasikan dengan tipe eksplisit?** Ya.
**5. Apakah menggunakan API versi lama?** Tidak, menggunakan `AsyncNotifier`.
**6. Hasil test?** Uji coba lolos setelah penyesuaian durasi animasi pada widget test.

## Praktikum 3 - AsyncValue: loading, error, success
-
Refleksi: 
    Menampilkan ulang data lama (stale data) dengan indikator refresh (seperti pull-to-refresh atau loading bar di atas) jauh lebih baik daripada mengosongkan layar ke state loading murni karena mempertahankan konteks pengguna (user context). Mengubah layar menjadi kosong setiap kali terjadi pembaruan akan menyebabkan layout shift yang kasar dan memberi kesan aplikasi lambat. Pengguna kehilangan kemampuan untuk membaca data yang sudah ada sambil menunggu data baru.

    Pola ini sangat krusial diimplementasikan pada aplikasi yang berbasis linimasa atau data yang terus diperbarui secara dinamis, seperti feed media sosial, aplikasi berita, daftar produk (e-commerce), atau dasbor metrik, di mana retensi informasi di layar meningkatkan kenyamanan pengalaman pengguna (UX).

![alt text](<screenshots/Praktikum 3 - AsyncValue loading error success/image.png>) 
![alt text](<screenshots/Praktikum 3 - AsyncValue loading error success/Screenshot 2026-09-22 110636.png>) 
![alt text](<screenshots/Praktikum 3 - AsyncValue loading error success/Screenshot 2026-09-22 111742.png>)

## Praktikum 4 - AI Challenge
-
    ### AI Verification Checklist
    **Oleh:** Aditya Rizqiqa Ramadhan (TI-3E)

    1. Apakah state diubah secara immutable (tidak ada state.add() atau mutasi list langsung)?**
    **Ya, sudah diubah secara immutable.** Pada `StatsNotifier`, pembaruan data mengembalikan *list* baru secara utuh (`return ['Total Pengguna...', ...]`). Saat proses pembaharuan data asinkron via metode `retry()`, state ditimpa langsung dengan nilai asinkron baru via `state = await AsyncValue.guard(...)` tanpa melakukan mutasi langsung pada memori *list*.

    2. Apakah ref.watch hanya dipakai di dalam build, dan ref.read di callback?**
    **Ya.** Pemanggilan `final statsAsync = ref.watch(statsProvider)` berada persis di dalam metode `build()` pada `StatsPage`. Pemanggilan `ref.read(statsProvider.notifier).retry()` berada di dalam callback `onPressed` pada tombol *retry* (Coba Lagi), sesuai dengan *best practice* Riverpod.

    3. Apakah ketiga state AsyncValue benar-benar ditangani (bukan hanya success)?**
    **Ya, ter-handle secara menyeluruh.** Implementasi UI menggunakan ekstensi `.when(loading: ..., error: ..., data: ...)` dari tipe `AsyncValue`. Ini menjamin *compiler* akan menuntut ketiga kemungkinan state asinkron digambar di layar: `CircularProgressIndicator` untuk *loading*, pesan *error* dan tombol *retry* untuk gagal, dan `ListView.builder` untuk data sukses.

    4. Apakah provider dideklarasikan dengan tipe eksplisit dan tidak duplikat dengan provider lain?**
    **Ya.** Provider dideklarasikan dengan pengetikan generik yang jelas: `AsyncNotifierProvider<StatsNotifier, List<String>>`. Objek yang di-return dari *build* secara eksplisit dibatasi pada tipe `List<String>`.

    5. Apakah kode AI memakai API Riverpod versi lama (StateProvider antipattern, StateNotifierProvider usang, atau Consumer bertingkat)?**
    **Tidak, kodenya menggunakan API modern Riverpod 2.x.** Kode ini menghindari arsitektur *legacy* `StateNotifierProvider`. Sebagai gantinya, ia menggunakan kelas `AsyncNotifier<T>` yang dihubungkan dengan `AsyncNotifierProvider`, pola paling mutakhir yang direkomendasikan pencipta Riverpod (Remi Rousselet) untuk state asinkron.

    6. Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?**
    **Lolos tanpa masalah.** Kodingan mematuhi pedoman linter bawaan Dart. Uji coba (test) dibuat tangguh (tidak *flaky*) terhadap probabilitas error 30% dengan mengecek *initial state* (`AsyncLoading`) dan *final resolution state* (baik sukses maupun gagal, asalkan bukan lagi *loading*).

![alt text](<screenshots/Praktikum 4 - AI Challenge/image.png>)


## Lampiran dokumentasi:
![alt text](<screenshots/Praktikum 1 - Aplikasi multi-page dengan GoRouter/image.png>)
![alt text](<screenshots/Praktikum 2 - Aplikasi ToDo dengan Riverpod/image.png>) 
![alt text](<screenshots/Praktikum 2 - Aplikasi ToDo dengan Riverpod/Screenshot 2026-09-22 104537.png>) 
![alt text](<screenshots/Praktikum 2 - Aplikasi ToDo dengan Riverpod/Screenshot 2026-09-22 104723.png>)
![alt text](<screenshots/Praktikum 3 - AsyncValue loading error success/image.png>) 
![alt text](<screenshots/Praktikum 3 - AsyncValue loading error success/Screenshot 2026-09-22 110636.png>) 
![alt text](<screenshots/Praktikum 3 - AsyncValue loading error success/Screenshot 2026-09-22 111742.png>)
![alt text](<screenshots/Praktikum 4 - AI Challenge/image.png>)
![alt text](<screenshots/Praktikum 5 - Refactoring Challenge/image.png>) 
![alt text](<screenshots/Praktikum 5 - Refactoring Challenge/Screenshot 2026-09-22 192800.png>) 
![alt text](<screenshots/Praktikum 5 - Refactoring Challenge/Screenshot 2026-09-22 192846.png>) 
![alt text](<screenshots/Praktikum 5 - Refactoring Challenge/Screenshot 2026-09-22 192922.png>)