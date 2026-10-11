# Laporan Praktikum Minggu 6: Authentication, Security & FCM
**Mata Kuliah: Pemrograman Mobile (Polinema)**

Aplikasi: **Campus Notification App (`campus_notify`)**  
Topik: Autentikasi dengan Secure Storage & Token Refresh, Integrasi Firebase Cloud Messaging (FCM), Izin Runtime Notifikasi, Siklus Hidup Token, serta Penanganan Deep Link pada Tiga App State (*Foreground*, *Background*, *Terminated*).

---

## 1. Stack Teknologi & Paket Dependensi

* **Framework**: Flutter SDK (Dart 3.x)
* **State Management**: `flutter_riverpod` (Notifier & AsyncNotifier pattern)
* **Routing & Deep Link**: `go_router` (dengan route guard redirect berbasis status auth)
* **HTTP Client**: `dio` (dengan interceptor auto-refresh saat token kedaluwarsa 401)
* **Penyimpanan Kredensial Aman**: `flutter_secure_storage` (Keystore pada Android / Keychain pada iOS)
* **Push Notification Service**: `firebase_core`, `firebase_messaging`
* **Local Notifications**: `flutter_local_notifications` (untuk banner notifikasi foreground)

---

## 2. Struktur Proyek (`campus_notify`)

```text
06-week-6-authentication-security-fcm/
├── README.md                      # Laporan praktikum, dokumentasi fitur, matriks uji & refleksi
├── docs/
│   └── ai_verification.md         # Dokumentasi AI Prompt Challenge & AI Verification Checklist
├── screenshots/                   # Folder bukti pengujian banner & deep link di tiap state
│   ├── README.md                  # Panduan peletakan screenshot
│   ├── fcm-console-test.png       # Bukti uji coba pengiriman pertama dari Firebase Console
│   ├── fcm-foreground.png         # Bukti notifikasi lokal saat aplikasi dibuka
│   ├── fcm-background.png         # Bukti notifikasi banner sistem saat diminimalkan
│   └── fcm-terminated.png         # Bukti notifikasi membuka aplikasi saat dimatikan
└── campus_notify/
    ├── lib/
    │   ├── main.dart              # Inisialisasi Firebase, GoRouter guard, bootstrap aplikasi
    │   ├── routes.dart            # Konstanta rute terpusat & fungsi murni routeFromMessage
    │   ├── data/
    │   │   ├── auth_repository.dart   # Model sesi auth & mock service login/refresh
    │   │   ├── token_store.dart       # Penyimpanan token aman (flutter_secure_storage)
    │   │   ├── api_client.dart        # Dio client dengan auto-refresh 401 interceptor
    │   │   └── api_errors.dart        # Pemetaan DioException ke pesan ramah pengguna
    │   ├── providers/
    │   │   └── auth_providers.dart    # Riverpod provider untuk Auth, TokenStore, dan FCM Token
    │   ├── messaging/
    │   │   └── push_service.dart      # Permission, token lifecycle, local notification, dan 3 app state handlers
    │   └── pages/
    │       ├── login_page.dart        # Halaman autentikasi login
    │       ├── home_page.dart         # Halaman utama (debug FCM token terpotong, permission, dan status topik)
    │       └── announcement_page.dart # Halaman detail pengumuman tujuan deep link (/pengumuman/:id)
    └── test/
        ├── auth_push_test.dart        # Unit test logika route parser, auth/refresh, dan api_errors
        └── widget_test.dart           # Smoke test parsing rute
```

---

## 3. Rangkuman Praktikum

### Praktikum 1: Autentikasi, Secure Storage & Refresh Token
1. **Penyimpanan Kredensial Aman (`TokenStore`)**:
   Token tidak disimpan di `SharedPreferences` (karena tidak terenkripsi), melainkan di `flutter_secure_storage` (Android Keystore).
2. **Auto-Refresh Token (`Dio Interceptor`)**:
   Saat request menghasilkan HTTP `401 Unauthorized`, interceptor otomatis mengambil refresh token, meminta access token baru, menyimpan token baru, dan mengulang kembali request yang gagal secara transparan. Jika refresh token juga gagal/expired, seluruh sesi dibersihkan dan pengguna diarahkan ke `/login`.
3. **Route Guard (`GoRouter`)**:
   Pengguna yang belum login otomatis dialihkan ke `/login`. Setelah berhasil login, diarahkan ke `/`.

### Praktikum 2: FCM, Permission, dan Token Lifecycle
1. **Pendaftaran Firebase**:
   Mendaftarkan `applicationId` Android (`com.example.campus_notify`), menyertakan plugin `google-services`, dan inisialisasi `Firebase.initializeApp()`.
2. **Izin Notifikasi Runtime**:
   Meminta izin notifikasi runtime Android 13+ (`POST_NOTIFICATIONS`) dan iOS melalui `FirebaseMessaging.instance.requestPermission()`.
3. **Token Lifecycle**:
   * Mengambil registration token via `getToken()`.
   * Memasang listener `onTokenRefresh` agar backend selalu mendapatkan token terbaru saat token berganti (reinstall/clear cache/rotasi).
   * Berlangganan topik siaran massal `pengumuman-kampus`.
4. **Prinsip Keamanan Token**:
   Token FCM pada antarmuka debug dipotong menjadi 12 karakter pertama + `...` agar aman dan tidak bocor ke publik.

### Praktikum 3: Foreground, Background, Terminated & Deep Link
Campus Notification App menangani tiga kondisi state aplikasi menggunakan payload gabungan:
* **Notification Payload**: Berisi `title` dan `body` untuk teks yang dibaca manusia.
* **Data Payload**: Berisi `route` (`/pengumuman/3`) dan `id` (`3`) untuk navigasi deep link.

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

---

## 4. Matriks Pengujian Tiga App State (Wajib)

| App State | Perilaku Banner Sistem | Handler yang Menangkap | Aksi Klik / Navigasi Deep Link | File Bukti Screenshot |
| :--- | :--- | :--- | :--- | :--- |
| **Foreground** *(Aplikasi sedang dibuka)* | Sistem Android **tidak** menampilkan banner otomatis. | Ditangkap oleh `FirebaseMessaging.onMessage`. Banner ditampilkan manual via `flutter_local_notifications`. | Mengetuk banner lokal memanggil callback `onDidReceiveNotificationResponse` -> `router.go('/pengumuman/3')`. | `screenshots/fcm-foreground.png` |
| **Background** *(Aplikasi diminimalkan / tekan Home)* | Sistem Android **otomatis** memunculkan banner notifikasi di status bar. | Ditangkap oleh `firebaseMessagingBackgroundHandler` (top-level `@pragma('vm:entry-point')`). | Mengetuk banner sistem memanggil `FirebaseMessaging.onMessageOpenedApp` -> `router.go('/pengumuman/3')`. | `screenshots/fcm-background.png` |
| **Terminated** *(Aplikasi ditutup/di-kill total)* | Sistem Android **otomatis** memunculkan banner notifikasi di status bar. | Ditangkap oleh sistem Android OS. | Mengetuk banner membuka aplikasi dari keadaan mati -> `FirebaseMessaging.instance.getInitialMessage()` membaca payload data dan mengarahkan ke `/pengumuman/3`. | `screenshots/fcm-terminated.png` |

---

## 5. Cara Menjalankan & Validasi Pengujian

### A. Uji Statis & Analisis Kode
```bash
cd campus_notify
flutter analyze
```
*Hasil: `No issues found!`*

### B. Menjalankan Unit Test
```bash
flutter test
```
*Hasil:*
```text
00:00 +0: routeFromMessage menangani route kosong dan tanpa slash
00:00 +1: data payload membawa id pengumuman
00:00 +2: provider auth membaca status login dari token
00:00 +3: refresh gagal -> sesi dibersihkan (paksa login ulang)
00:00 +4: readableApiError memetakan DioException ke pesan ramah pengguna
00:00 +5: App smoke test for route parsing
00:00 +6: All tests passed!
```

### C. Menjalankan Aplikasi di Perangkat / Emulator Android
Pastikan berkas `google-services.json` telah diunduh dari Firebase Console ke `campus_notify/android/app/google-services.json`.
```bash
flutter run
```

---

## 6. Refleksi & Jawaban Pertanyaan Modul

1. **Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?**  
   *Jawaban:* `SharedPreferences` menyimpan data dalam bentuk berkas XML teks biasa tanpa enkripsi di direktori aplikasi. Jika perangkat di-root, terserang malware, atau diekstrak via ADB backup, penyerang dapat membaca refresh token dengan mudah. Karena masa berlaku refresh token panjang (mingguan/bulanan), penyerang dapat memanfaatkannya untuk terus meminta access token baru dan membajak sesi pengguna secara permanen. Oleh karena itu, wajib menggunakan `flutter_secure_storage` yang memanfaatkan perangkat keras keamanan bawaan OS (Android Keystore / iOS Keychain).

2. **Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester perkuliahan?**  
   *Jawaban:* Token registrasi FCM tidak bersifat statis permanen. Token dapat diperbarui sewaktu-waktu oleh Firebase (misalnya akibat pembersihan memori/cache, pembaruan aplikasi/OS, atau kebijakan rotasi keamanan). Jika aplikasi tidak memasang listener `onTokenRefresh`, backend kampus akan tetap menyimpan token lama yang sudah mati (*stale token*). Akibatnya, seluruh push notification (seperti pengumuman jadwal kuliah darurat, revisi ruang ujian, atau info nilai) tidak akan pernah diterima oleh mahasiswa tersebut selama satu semester penuh.

3. **Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.**  
   * *Topik Messaging (`subscribeToTopic`)*: Digunakan untuk pesan **broadcast (siaran massal)** di mana satu pesan dikirimkan ke ribuan mahasiswa sekaligus secara efisien tanpa backend perlu menyimpan jutaan token individual.  
     *Contoh*: "Pemberitahuan: Seluruh perkuliahan hari Senin diliburkan karena Dies Natalis Politeknik Negeri Malang."
   * *Device Token Messaging*: Digunakan untuk pesan **personal, rahasia, atau transaksional** yang ditujukan khusus untuk satu akun mahasiswa tertentu.  
     *Contoh*: "Pengumuman Nilai: Nilai Akhir Semester mata kuliah Pemrograman Mobile Anda telah dirilis." atau "Peringatan: Tagihan UKT Semester 6 Anda jatuh tempo dalam 3 hari."

4. **Bagian mana dari draf AI yang perlu diperbaiki dan mengapa?**  
   * *Background Handler*: Draf AI awal sering menjadikannya sebagai *method* di dalam kelas atau mencoba mengakses `BuildContext`. Ini diperbaiki menjadi fungsi top-level bertanda `@pragma('vm:entry-point')` karena dijalankan pada Dart Isolate terpisah yang tidak memiliki widget tree.
   * *Pencegahan Token Leak*: AI awal sering menyertakan `print(token)` utuh. Kami memperbaikinya dengan memotong token (12 karakter + `...`) di debug UI dan tidak mencetaknya utuh ke console demi kepatuhan prinsip keamanan OWASP Mobile.
   * *Safe Guard Inisialisasi Firebase*: Menambahkan pengecekan ketersediaan Firebase (`Firebase.apps.isNotEmpty`) agar aplikasi tidak mengalami runtime crash jika dijalankan di platform tanpa inisialisasi Firebase.

---

## 7. Checklist Evaluasi Tugas (Mini Project / Industry Challenge)

Sesuai 8 butir tugas akhir modul Codelab:

- [x] **1. Login dengan Guard Route**: Belum login selalu diarahkan ke `/login`, setelah login diarahkan ke `/`.
- [x] **2. Token di Secure Storage & Auto-Refresh Dio**: Disimpan di `TokenStore` (Keystore/Keychain), Dio me-refresh 1 kali saat 401 dan logout otomatis jika refresh gagal.
- [x] **3. Integrasi FCM Lengkap**: Izin runtime diminta, `getToken` + `onTokenRefresh` disinkronkan ke backend (simulasi `POST /devices`), dan subscribe topik `pengumuman-kampus`.
- [x] **4. Notifikasi Gabungan & Deep Link 3 State**: Payload `notification + data` membuka rute `/pengumuman/:id` pada Foreground, Background, dan Terminated.
- [x] **5. Bukti Screenshots**: Struktur folder `screenshots/` disiapkan untuk bukti token terpotong, banner tiap state, dan halaman tujuan deep link.
- [x] **6. Minimal 2 Test Lulus**: Menyertakan 6 unit test yang lulus 100% di `test/auth_push_test.dart` dan `test/widget_test.dart`.
- [x] **7. Dokumentasi AI Challenge**: Tersimpan lengkap di `docs/ai_verification.md` mencakup prompt, checklist verifikasi, temuan perbaikan, dan matriks pengujian.
- [x] **8. Struktur Folder Portofolio**: Rapi dan lengkap (`lib/`, `test/`, `docs/`, `screenshots/`, `README.md`) siap untuk di-push ke repository.

---

## 8. Referensi Pendukung Resmi

* [Slide Week 6: Authentication, Security & FCM](https://jti-polinema.github.io/flutter-codelab/00-slides/Week_06_Authentication_Security_FCM.html)
* [Firebase Cloud Messaging Flutter Client Guide](https://firebase.google.com/docs/cloud-messaging/flutter/client)
* [FCM Message Types: Notification vs Data Payload](https://firebase.google.com/docs/cloud-messaging/concept-options)
* [Firebase Auth for Flutter](https://firebase.google.com/docs/auth/flutter/start)
* [flutter_secure_storage Package (pub.dev)](https://pub.dev/packages/flutter_secure_storage)
* [flutter_local_notifications Package (pub.dev)](https://pub.dev/packages/flutter_local_notifications)
* [GoRouter: Redirect & Deep Linking Documentation](https://go_router.dev/)
* [OWASP Mobile Top 10 Security Risks](https://owasp.org/www-project-mobile-top-10/)
* [Learn Dart in Y Minutes](https://learnxinyminutes.com/dart/)
