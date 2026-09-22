import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week3_todo/main.dart'; // Pastikan import sesuai

void main() {
  testWidgets('menambah tugas baru', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    expect(find.text('Belum ada tugas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Menunggu dialog terbuka penuh

    await tester.enterText(find.byType(TextField), 'Kerjakan PR minggu 3');
    await tester.tap(find.text('Tambah'));
    
    // UBAH BARIS INI: Gunakan pumpAndSettle agar dialog benar-benar tertutup
    await tester.pumpAndSettle(); 

    // Sekarang hanya akan menemukan tepat satu teks di dalam list
    expect(find.text('Kerjakan PR minggu 3'), findsOneWidget);
  });
}