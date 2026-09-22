import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_providers.dart';

// [PENJELASAN] Menggunakan ConsumerWidget agar dapat mengakses objek ref.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [PENJELASAN] ref.watch HANYA diletakkan di dalam fungsi build untuk memantau perubahan state secara reaktif.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Statistik')),
      // [PENJELASAN] Pattern matching (.when) mewajibkan penanganan ketiga kondisi state asinkron.
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terjadi Kesalahan: $error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                // [PENJELASAN] ref.read digunakan di dalam callback (onPressed) untuk memanggil fungsi, BUKAN untuk memantau UI.
                onPressed: () => ref.read(statsProvider.notifier).retry(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        data: (stats) => ListView.builder(
          itemCount: stats.length, // [PENJELASAN] Menampilkan 3 item sesuai request.
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.analytics),
            title: Text(stats[index]),
          ),
        ),
      ),
    );
  }
}