import 'package:clean_architecture/features/notes/domain/entities/note.dart';
import 'package:clean_architecture/features/notes/domain/usecases/search_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SearchNotes searchNotes;
  late List<Note> sampleNotes;

  setUp(() {
    searchNotes = const SearchNotes();
    sampleNotes = [
      Note(
        id: 1,
        title: 'Kuliah Pemrograman Mobile',
        body: 'Mempelajari Clean Architecture dan Riverpod',
        updatedAt: DateTime(2026, 11, 16),
      ),
      Note(
        id: 2,
        title: 'Belajar Flutter State Management',
        body: 'Eksplorasi Notifier dan AsyncValue',
        updatedAt: DateTime(2026, 11, 15),
      ),
      Note(
        id: 3,
        title: 'Tugas Praktikum Database SQLite',
        body: 'Integrasi sqflite lokal untuk offline-first',
        updatedAt: DateTime(2026, 11, 14),
      ),
    ];
  });

  group('SearchNotes Use Case Unit Tests', () {
    test('Pencarian sukses: case-insensitive dan spasi berlebih cocok', () {
      final result = searchNotes(notes: sampleNotes, query: '   FLuTTeR   ');

      expect(result.length, 1);
      expect(result.first.id, 2);
      expect(result.first.title, 'Belajar Flutter State Management');
    });

    test(
      'Pencarian kosong: query tidak cocok mengembalikan list kosong []',
      () {
        final result = searchNotes(
          notes: sampleNotes,
          query: 'NonExistentTitleKeywordXYZ',
        );

        expect(result, isEmpty);
        expect(result, equals(<Note>[]));
      },
    );

    test('Query kosong mengembalikan seluruh daftar catatan asli', () {
      final result = searchNotes(notes: sampleNotes, query: '    ');

      expect(result.length, sampleNotes.length);
      expect(result, equals(sampleNotes));
    });
  });
}
