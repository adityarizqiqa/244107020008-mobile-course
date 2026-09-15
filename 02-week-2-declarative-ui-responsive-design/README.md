Hasil AI Challenge:

1. Perbandingan Tata Letak (GridView vs LayoutBuilder + Column)
Pertanyaan: Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya.

Jawaban Analisis:

- Versi GridView:
- Kelebihan: Sangat mudah dan ringkas diimplementasikan untuk grid 2 dimensi. Sangat cocok jika semua kartu memiliki rasio tinggi/lebar yang seragam.
- Trade-off (Responsif & Aksesibilitas): GridView bergantung pada childAspectRatio. Jika pengguna membesarkan ukuran font sistem (untuk aksesibilitas penglihatan), teks bisa overflow atau terpotong karena tinggi kartu dipaksa statis oleh rasio tersebut, terlepas dari isi kontennya.

- Versi LayoutBuilder + Column/Row (atau Wrap):
- Kelebihan: Jauh lebih fleksibel untuk aksesibilitas. Tinggi Row atau Column bisa membesar secara alami mengikuti ukuran teks (jika font dibesarkan).
- Trade-off: Membutuhkan boilerplate kode yang lebih banyak (perlu mengatur spasi antar elemen secara manual dan membungkus elemen dengan Flexible/Expanded).

2. Penguatan Konsep (Bahaya Expanded)
Pertanyaan: Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya.

Jawaban Analisis:
Expanded menuntut (memaksa) widget induknya untuk memiliki ukuran batas pasti (bounded constraints) yang bisa ia penuhi. Expanded akan menyebabkan error (seperti RenderFlex children have non-zero flex but incoming constraints are unbounded) jika diletakkan di dalam induk yang ukurannya "tidak terbatas" (unbounded), seperti di dalam SingleChildScrollView berarah horizontal atau di dalam Row yang bersarang di dalam Row lain tanpa pembatas.

3. Verification Prompt (Audit Layout)
Pertanyaan: Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?

- Hasil Audit AI:
- Responsivitas (< 600px): Aman. Breakpoint di-set pada kWideBreakpoint = 700. Jika layar berada di bawah 600px, nilai kembalian akan masuk ke kondisi false (1 kolom). Layar sempit akan menampilkan kartu bersusun secara vertikal tanpa terpotong.
- Aksesibilitas: Terjaga. Label Semantics telah dipasang secara presisi pada switch mode gelap dan juga pada InfoCard (excludeSemantics: true mencegah pembacaan terpisah antara title dan value). Penggunaan warna sudah 100% bergantung pada Theme.of(context) memastikan rasio kontras warna aman (Material 3 standard).
- Stabilitas Widget: Seluruh widget yang digunakan (LayoutBuilder, GridView, CupertinoSwitch, Semantics) adalah widget inti di Flutter Stable dan tidak ada yang berstatus deprecated.

Dokumentasi:

Praktikum layout sederhana (warm-up):
![alt text](<screenshots/Praktikum layout sederhana (warm-up)/Hasil penambahan row + expanded dan data diri.png>) 
![alt text](<screenshots/Praktikum layout sederhana (warm-up)/layout sederhana (warm-up).png>) 
![alt text](<screenshots/Praktikum layout sederhana (warm-up)/Menghapus Expanded.png>) 
![alt text](<screenshots/Praktikum layout sederhana (warm-up)/Mengubah MainAxisSize.min ke nilai default.png>) 
![alt text](<screenshots/Praktikum layout sederhana (warm-up)/Penambahan Row + Expanded.png>) 
![alt text](<screenshots/Praktikum layout sederhana (warm-up)/Ukuran box setelah dirubah.png>)

Praktikum dashboard responsif:
![alt text](<screenshots/Praktikum dashboard responsif/Hasil run awal.png>) 
![alt text](<screenshots/Praktikum dashboard responsif/Landscape Dark.jpeg>) 
![alt text](<screenshots/Praktikum dashboard responsif/Landscape Light.jpeg>) 
![alt text](<screenshots/Praktikum dashboard responsif/Menambahkan interaksi StatefulWidget dan Cupertino 1.png>) 
![alt text](<screenshots/Praktikum dashboard responsif/Potrait Dark.jpeg>) 
![alt text](<screenshots/Praktikum dashboard responsif/Potrait Light.jpeg>) 
![alt text](<screenshots/Praktikum dashboard responsif/Run 1 Statefull widget.png>) 
![alt text](<screenshots/Praktikum dashboard responsif/Run 2 Statefull widget.png>) 
![alt text](<screenshots/Praktikum dashboard responsif/Run Cupertino 1.png>) 
![alt text](<screenshots/Praktikum dashboard responsif/Run Cupertino 2.png>) 
![alt text](<screenshots/Praktikum dashboard responsif/Theme system 1.jpeg>) 
![alt text](<screenshots/Praktikum dashboard responsif/Theme system 2.jpeg>)

Tugas dan AI design exploration:
![alt text](<screenshots/Tugas dan AI design exploration/Dark theme landscape.png>)
![alt text](<screenshots/Tugas dan AI design exploration/Dark theme potrait.png>) 
![alt text](<screenshots/Tugas dan AI design exploration/Hasil Analyze.png>) 
![alt text](<screenshots/Tugas dan AI design exploration/Hasil test.png>) 
![alt text](<screenshots/Tugas dan AI design exploration/Light theme landscape.png>) 
![alt text](<screenshots/Tugas dan AI design exploration/Light theme potrait.png>) 
![alt text](<screenshots/Tugas dan AI design exploration/Testing 1 Responsive academic dashboard .png>) 
![alt text](<screenshots/Tugas dan AI design exploration/Testing 2 Responsive academic dashboard.png>)

