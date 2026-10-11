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
campus_notify/
├── lib/
│   ├── main.dart                  # Inisialisasi Firebase, GoRouter guard, bootstrap aplikasi
│   ├── routes.dart                # Konstanta rute terpusat & fungsi murni routeFromMessage
│   ├── data/
│   │   ├── auth_repository.dart   # Model sesi auth & mock service login/refresh
│   │   ├── token_store.dart       # Penyimpanan token aman (flutter_secure_storage)
│   │   └── api_client.dart        # Dio client dengan auto-refresh 401 interceptor
│   ├── providers/
│   │   └── auth_providers.dart    # Riverpod provider untuk Auth, TokenStore, dan FCM Token
│   ├── messaging/
│   │   └── push_service.dart      # Permission, token lifecycle, local notification, dan 3 app state handlers
│   └── pages/
│       ├── login_page.dart        # Halaman autentikasi login
│       ├── home_page.dart         # Halaman utama (debug FCM token, permission, dan status topik)
│       └── announcement_page.dart # Halaman detail pengumuman tujuan deep link (/pengumuman/:id)
├── test/
│   ├── auth_push_test.dart        # Unit test logika route parser & auth/refresh
│   └── widget_test.dart           # Smoke test parsing rute
├── docs/
│   └── ai_verification.md         # Dokumentasi AI Prompt Challenge & AI Verification Checklist
└── screenshots/                   # Bukti pengujian aplikasi pada tiap state
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
00:00 +4: App smoke test for route parsing
00:00 +5: All tests passed!
```

### C. Menjalankan Aplikasi di Perangkat / Emulator Android
Pastikan berkas `google-services.json` telah diunduh dari Firebase Console ke `android/app/google-services.json`.
```bash
flutter run
```

---

## 6. Refleksi & Jawaban Pertanyaan Modul

1. **Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?**  
   *Jawaban:* `SharedPreferences` menyimpan data dalam bentuk berkas XML teks biasa tanpa enkripsi. Jika perangkat di-root atau dicadangkan (ADB backup), penyerang dapat mengekstrak refresh token. Karena refresh token memiliki masa aktif yang panjang, penyerang dapat terus menerus mencetak access token baru dan membajak akun pengguna. Selalu gunakan `flutter_secure_storage` yang memanfaatkan Android Keystore / iOS Keychain.

2. **Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester perkuliahan?**  
   *Jawaban:* Registration token FCM dapat berubah sewaktu-waktu (misal setelah pembaruan OS, pembersihan cache, atau rotasi keamanan otomatis oleh Firebase). Jika aplikasi tidak mendengarkan `onTokenRefresh`, backend akan tetap menyimpan token lama yang sudah tidak valid (stale token). Akibatnya, notifikasi pengumuman jadwal atau nilai tidak akan pernah sampai ke perangkat mahasiswa tersebut.

3. **Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.**  
   * *Topik Messaging (`subscribeToTopic`)*: Digunakan untuk pesan **broadcast (massal)** ke banyak pengguna sekaligus tanpa backend harus menyimpan daftar jutaan token satu per satu. Contoh: Pengumuman libur semester, peringatan bencana, atau jadwal KRS umum satu jurusan.
   * *Device Token Messaging*: Digunakan untuk pesan **personal / rahasia** yang ditujukan hanya untuk satu orang spesifik. Contoh: Notifikasi nilai mata kuliah, reminder tagihan UKT mahasiswa, atau kode OTP login.

4. **Bagian mana dari draf AI yang perlu diperbaiki dan mengapa?**  
   * Background handler wajib dijadikan fungsi top-level dan ditandai dengan `@pragma('vm:entry-point')` agar tidak dihapus oleh tree-shaking kompiler Dart dan dapat diakses dari background isolate terpisah.
   * Menghilangkan pencetakan token utuh pada log debug / UI (hanya boleh terpotong 12 digit + `...`) demi privasi dan kepatuhan standar keamanan OWASP Mobile.
