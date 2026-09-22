import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week3_todo/providers/stats_providers.dart'; // Sesuaikan path jika berbeda

void main() {
  test('StatsNotifier menangani state loading lalu menyelesaikannya dengan data atau error', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialState = container.read(statsProvider);
    expect(initialState, isA<AsyncLoading<List<String>>>());

    // Menggunakan try-catch agar Future tereksekusi sempurna di environment test
    try {
      await container.read(statsProvider.future);
    } catch (e) {
      // Abaikan eksepsi karena ini adalah simulasi error 30%
    }

    final finalState = container.read(statsProvider);
    expect(finalState.isLoading, false, reason: 'Setelah selesai, tidak boleh dalam state loading');
    expect(finalState.hasValue || finalState.hasError, true, reason: 'Harus berupa Data atau Error');
  });
}