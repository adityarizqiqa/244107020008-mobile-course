import 'package:clean_architecture/features/notes/domain/entities/note.dart';
import 'package:clean_architecture/features/notes/presentation/pages/notes_page.dart';
import 'package:clean_architecture/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Menampilkan search empty state saat query tidak cocok dengan catatan apa pun',
    (tester) async {
      final sampleNotes = [
        Note(
          id: 1,
          title: 'Praktikum Flutter Riverpod',
          body: 'Implementasi Clean Architecture',
          updatedAt: DateTime(2026, 11, 16),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesProvider.overrideWith((ref) async => sampleNotes),
            dirtyCountProvider.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(home: NotesPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan item awal muncul
      expect(find.text('Praktikum Flutter Riverpod'), findsOneWidget);

      // Ketikkan kata kunci yang tidak ada di judul catatan mana pun
      final searchField = find.byKey(const Key('notes_search_field'));
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'KataKunciYangPastiTidakAda123');
      await tester.pumpAndSettle();

      // Verifikasi item lama disembunyikan dan widget empty state muncul
      expect(find.text('Praktikum Flutter Riverpod'), findsNothing);
      expect(find.text('Tidak ada catatan ditemukan'), findsOneWidget);
      expect(find.byKey(const Key('notes_search_empty_state')), findsOneWidget);
      expect(find.text('Reset Pencarian'), findsOneWidget);
    },
  );
}
