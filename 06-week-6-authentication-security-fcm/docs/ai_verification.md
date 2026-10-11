# AI Prompt Challenge & AI Verification Checklist
**Codelab Minggu 6: Authentication, Security & FCM**

## 1. Prompt AI yang Digunakan
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

## 2. AI Verification Checklist & Temuan Teknis

| Butir Verifikasi | Status | Temuan & Tindakan Perbaikan |
| :--- | :---: | :--- |
| **Background Handler Top-Level** | **Valid** | Fungsi `firebaseMessagingBackgroundHandler` dibuat sebagai fungsi top-level di luar kelas dan diberi `@pragma('vm:entry-point')` agar tidak dihapus oleh optimasi AOT kompiler Dart dan dapat dipanggil isolate background native Android/iOS. |
| **Tidak Mengakses BuildContext di Background** | **Valid** | Di dalam `firebaseMessagingBackgroundHandler`, tidak ada pemanggilan `BuildContext`, Riverpod, atau navigasi UI. Navigasi hanya dipicu saat pengguna melakukan klik pada banner. |
| **Pembaruan Token Nyata (`onTokenRefresh`)** | **Valid** | Listener `onTokenRefresh` memanggil callback `onToken` untuk menyinkronkan token baru ke backend / state, bukan hanya sekadar dicetak ke `print()`. |
| **Foreground Local Notifications Manual** | **Valid** | Menggunakan `_local.show(...)` dengan named parameter `settings:` pada saat inisialisasi untuk menampilkan banner saat aplikasi di foreground. |
| **Penanganan Klik di 3 App State** | **Valid** | Menggunakan fungsi murni `routeFromMessage` untuk mengekstrak `data.route` dan mengarahkan pengguna ke `/pengumuman/:id` di GoRouter. |
| **Sanitasi Keamanan Token** | **Valid** | Token FCM di halaman antarmuka dipotong 12 digit pertama + `...` dan tidak pernah diekspos utuh ke console log atau UI screenshot. |

---

## 3. Matriks Hasil Uji Tiga App State

| App State | Payload Uji | Handler Aktif | Hasil Navigasi | Bukti |
| :--- | :--- | :--- | :--- | :--- |
| **Foreground** | `{"notification": {"title": "Jadwal Baru"}, "data": {"route": "/pengumuman/3"}}` | `FirebaseMessaging.onMessage` + Local Notification | Klik banner lokal -> Membuka `/pengumuman/3` | `screenshots/fcm-foreground.png` |
| **Background** | `{"notification": {"title": "Jadwal Baru"}, "data": {"route": "/pengumuman/3"}}` | `FirebaseMessaging.onMessageOpenedApp` | Klik banner status bar -> Membuka `/pengumuman/3` | `screenshots/fcm-background.png` |
| **Terminated** | `{"notification": {"title": "Jadwal Baru"}, "data": {"route": "/pengumuman/3"}}` | `FirebaseMessaging.instance.getInitialMessage()` | Ketuk notifikasi -> Aplikasi terbuka langsung ke `/pengumuman/3` | `screenshots/fcm-terminated.png` |
