# AI Prompt Challenge & AI Verification Checklist
**Codelab Minggu 6: Authentication, Security & FCM**

Dokumen ini disusun untuk memenuhi instrumen penilaian **AI Challenge**, **AI Verification Checklist**, dan **Refactoring Challenge** pada modul praktikum resmi Minggu 6.

---

## 1. AI Prompt Challenge

Berikut prompt yang diajukan ke AI coding assistant:

```text
Aplikasi Flutter Campus Notification App. Stack: firebase_messaging, flutter_local_notifications, flutter_secure_storage, go_router, Riverpod. Buatkan PushService dengan: 
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS, dan bagian yang tidak boleh mengakses BuildContext.
```

---

## 2. Analisis Perbedaan Platform: Android 13+ vs iOS

| Aspek | Android 13+ (API 33+) | iOS (Apple APNs) |
| :--- | :--- | :--- |
| **Izin Notifikasi Runtime** | Memerlukan runtime permission `android.permission.POST_NOTIFICATIONS` di manifest dan prompt dialog izin saat pertama kali diminta via `FirebaseMessaging.instance.requestPermission()`. | Menggunakan `UNUserNotificationCenter`. Izin diminta via prompt modal Apple dan memerlukan APNs Auth Key / Provisioning Profile di Apple Developer Console. |
| **Inisialisasi Banner Lokal** | Menggunakan `AndroidInitializationSettings('@mipmap/ic_launcher')` dan wajib mendefinisikan Notification Channel (`AndroidNotificationDetails`) dengan prioritas tinggi (`importance: Importance.high`). | Menggunakan `DarwinInitializationSettings()` dengan flag izin presentAlert, presentBadge, presentSound. |
| **Background Message Processing** | Pesan FCM dengan `notification` otomatis ditampilkan oleh sistem Android. Pesan *data-only* diproses oleh `firebaseMessagingBackgroundHandler` di latar belakang. | Memerlukan *Remote Notifications Background Mode* di Capabilities Xcode. Pesan dengan `content-available: 1` diperlukan untuk memicu background handler di iOS. |

---

## 3. Bagian yang TIDAK Boleh Mengakses `BuildContext`

1. **Background Handler (`firebaseMessagingBackgroundHandler`)**:
   * Dijalankan pada **Dart Isolate terpisah** dari isolate UI utama. Isolate ini tidak memiliki widget tree, tidak memiliki `BuildContext`, dan tidak dapat mengakses container Riverpod atau navigator GoRouter.
   * **Aturan**: Hanya boleh melakukan pemrosesan data ringan (misal penyimpanan lokal ke database/cache, logging). Navigasi baru boleh dipicu saat pengguna melakukan interaksi (klik/tap) pada banner notifikasi.
2. **Fungsi Lifecycle Service Tanpa UI**:
   * Registrasi token dan listener FCM (`onTokenRefresh`) harus independen dari siklus hidup widget agar tidak terputus saat halaman UI di-unmount. Navigasi diarahkan melalui callback rute atau state provider global.

---

## 4. AI Verification Checklist & Temuan Teknis

| Butir Verifikasi Modul | Status | Temuan Awal & Tindakan Perbaikan Manual |
| :--- | :---: | :--- |
| **Background Handler berupa fungsi top-level?** | **VALID** | Handler wajib fungsi top-level di luar kelas dan diberi `@pragma('vm:entry-point')` agar tidak dihapus oleh tree-shaking AOT Dart compiler. Draf AI awal yang menaruh handler di dalam method kelas ditolak. |
| **Pembaruan token nyata (`onTokenRefresh`)?** | **VALID** | Draf AI awal sering kali hanya melakukan `print(token)`. Kami memperbaiki agar listener memanggil callback `onToken` untuk menyinkronkan token baru ke provider state dan siap dikirim ke endpoint `POST /devices`. |
| **Foreground memakai Local Notification manual?** | **VALID** | Android & iOS secara default **tidak** menampilkan banner visual otomatis saat aplikasi di foreground. Local notification manual (`_local.show(...)`) wajib dipasang agar pengguna tetap menerima alert banner. |
| **Klik 3 state masuk ke rute yang benar?** | **VALID** | Seluruh state mengekstrak `data.route` via fungsi murni `routeFromMessage` dan diteruskan ke `GoRouter` (`/pengumuman/:id`). |
| **Token tidak di-hardcode & tidak di-log penuh?** | **VALID** | Token tidak disimpan di kode sumber. Di halaman debug antarmuka, token dipotong 12 karakter pertama + `...` sesuai standar keamanan data sensitif OWASP Mobile. |
| **Penanganan Safe Guard Inisialisasi Firebase?** | **VALID** | Menambahkan pengaman `Firebase.apps.isNotEmpty` agar pemanggilan `FirebaseMessaging.instance` tidak menimbulkan crash `[core/no-app]` jika dijalankan sebelum konfigurasi Firebase selesai. |

---

## 5. Bukti Refactoring Challenge

Sesuai tantangan refactoring pada modul:
1. **Konstanta Rute Terpusat ([lib/routes.dart](file:///d:/KULIAH%20TINGKAT%202/Semester%205/Repository/244107020008-mobile-course-1/06-week-6-authentication-security-fcm/campus_notify/lib/routes.dart))**:
   Semua string rute (`/login`, `/`, `/pengumuman/:id`) dipusatkan di kelas `AppRoutes` agar deep link dari FCM dan GoRouter konsisten.
2. **Ekstraksi Fungsi Murni `routeFromMessage`**:
   Logika parsing payload JSON dipisahkan ke fungsi murni tanpa ketergantungan pada runtime Firebase, sehingga dapat di-unit-test secara terisolasi di `test/auth_push_test.dart`.
3. **Pemetaan Pesan Error Ramah Pengguna ([lib/data/api_errors.dart](file:///d:/KULIAH%20TINGKAT%202/Semester%205/Repository/244107020008-mobile-course-1/06-week-6-authentication-security-fcm/campus_notify/lib/data/api_errors.dart))**:
   Fungsi `readableApiError(dynamic error)` memetakan status HTTP `401 Unauthorized`, `timeout`, `connectionError` (offline), dan status `500` ke pesan bahasa Indonesia yang ramah pengguna.

---

## 6. Penjelasan Siklus Hidup Token (Persiapan Demo Mahasiswa)

Untuk menjawab pertanyaan penguji saat sesi demo tanpa membaca catatan:
1. **Pendaftaran Awal (`getToken`)**:
   Saat aplikasi pertama kali dibuka dan meminta izin, FCM SDK berkomunikasi dengan server Firebase dan APNs/Google Play Services untuk menerbitkan registration token unik perangkat. Token ini disimpan di backend dan diasosiasikan dengan ID mahasiswa.
2. **Perubahan & Rotasi (`onTokenRefresh`)**:
   Token tidak bersifat permanen. Token dapat berganti saat:
   * Pengguna menghapus data aplikasi (*clear storage*) atau melakukan *reinstall*.
   * Terjadi rotasi keamanan berkala oleh server Firebase.
   * Aplikasi dipulihkan di perangkat baru (*device backup restore*).
   Jika listener `onTokenRefresh` tidak dipasang, backend akan menyimpan **token basi (stale token)**, mengakibatkan pesan notifikasi gagal terkirim selamanya ke mahasiswa tersebut.
3. **Topik Messaging vs Token**:
   * *Topik (`subscribeToTopic`)*: Digunakan untuk broadcast 1 pesan ke banyak mahasiswa (misal info kampus).
   * *Device Token*: Digunakan untuk pesan rahasia 1-ke-1 (misal notifikasi nilai atau tagihan).
