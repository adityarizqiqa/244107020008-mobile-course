import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets('App initializes and displays navigation items', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});

    await tester.pumpWidget(
      const ProviderScope(
        child: OfflineNotesApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catatan'), findsWidgets);
    expect(find.text('Cache API'), findsWidgets);
    expect(find.text('Pengaturan'), findsWidgets);
  });
}
