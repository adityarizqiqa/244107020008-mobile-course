import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// [PENJELASAN] Menggunakan AsyncNotifier untuk menangani state asinkron secara modern.
// Tipe kembalian didefinisikan secara eksplisit sebagai List<String>.
class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    return _fetchData();
  }

  // [PENJELASAN] Fungsi terpisah untuk mengambil data agar bisa digunakan ulang oleh fungsi retry().
  Future<List<String>> _fetchData() async {
    // [PENJELASAN] Delay 2 detik untuk mensimulasikan pemanggilan API/Network.
    await Future.delayed(const Duration(seconds: 2));

    // [PENJELASAN] Random generator untuk simulasi 30% kemungkinan gagal.
    final randomChance = Random().nextDouble();
    if (randomChance < 0.3) {
      throw Exception('Gagal memuat data (Simulasi 30% Error)');
    }

    // [PENJELASAN] Mengembalikan state immutable (list baru) berisi 3 item jika sukses.
    return ['Total Pengguna: 1,250', 'Pendapatan: \$450', 'Sesi Aktif: 3,400'];
  }

  // [PENJELASAN] Fungsi untuk memicu pengambilan data ulang dari UI saat terjadi error.
  Future<void> retry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchData());
  }
}

// [PENJELASAN] Deklarasi provider dengan tipe eksplisit dan menggunakan constructor reference (.new).
final statsProvider = AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);