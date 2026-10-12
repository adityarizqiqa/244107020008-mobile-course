import 'package:clean_architecture/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test loads Clean Architecture navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CleanArchitectureApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan navigasi tab Catatan dan Pengumuman tampil di layar
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Pengumuman'), findsOneWidget);
  });
}
