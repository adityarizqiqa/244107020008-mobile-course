import 'package:clean_architecture/core/failures.dart';
import 'package:clean_architecture/features/notes/domain/entities/note.dart';
import 'package:clean_architecture/features/notes/domain/repositories/note_repository.dart';
import 'package:clean_architecture/features/notes/domain/usecases/add_note.dart';
import 'package:clean_architecture/features/notes/domain/usecases/get_notes.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    if (fail) {
      return (
        notes: const <Note>[],
        failure: const LocalFailure('db locked (simulasi)'),
      );
    }
    return (notes: items, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    if (fail) {
      return (
        note: null,
        failure: const LocalFailure('db error'),
      );
    }
    final created = Note(
      id: items.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );
    return (note: created, failure: null);
  }

  @override
  Future<({Note? note, Failure? failure})> updateNote({
    required int id,
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) {
    throw UnimplementedError();
  }

  @override
  Future<({int count, Failure? failure})> countDirty() {
    throw UnimplementedError();
  }

  @override
  Future<({int syncedCount, Failure? failure})> syncNotes() {
    throw UnimplementedError();
  }
}

void main() {
  group('GetNotes Use Case Tests', () {
    test('GetNotes meneruskan daftar dari repository', () async {
      final repo = FakeNoteRepository(items: [
        Note(title: 'A', updatedAt: DateTime(2026, 9, 27)),
      ]);
      final result = await GetNotes(repo).call();
      expect(result.failure, isNull);
      expect(result.notes.length, 1);
      expect(result.notes.first.title, 'A');
    });

    test('GetNotes meneruskan failure tanpa melempar', () async {
      final repo = FakeNoteRepository(fail: true);
      final result = await GetNotes(repo).call();
      expect(result.failure, isA<LocalFailure>());
      expect(result.notes, isEmpty);
    });
  });

  group('AddNote Use Case Validation & Execution Tests', () {
    test('AddNote menolak input judul kosong dengan ValidationFailure', () async {
      final repo = FakeNoteRepository();
      final result = await AddNote(repo).call(title: '   ', body: 'Deskripsi');
      expect(result.failure, isA<ValidationFailure>());
      expect(result.note, isNull);
      expect(result.failure!.message, contains('tidak boleh kosong'));
    });

    test('AddNote berhasil menambahkan catatan dengan judul valid', () async {
      final repo = FakeNoteRepository();
      final result = await AddNote(repo).call(title: 'Catatan Baru', body: 'Isi');
      expect(result.failure, isNull);
      expect(result.note, isNotNull);
      expect(result.note!.title, 'Catatan Baru');
      expect(result.note!.dirty, isTrue);
    });
  });
}
