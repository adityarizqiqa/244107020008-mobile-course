import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/note.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.fetchNotes();
}, retry: (retryCount, error) => null);

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.countDirty();
});

class NoteRepository {
  NoteRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  // Fallback penyimpanan in-memory saat dijalankan di Web browser
  // karena SQLite platform channel hanya tersedia di mobile native (Android & iOS).
  static final List<Note> _webNotes = [];
  static int _nextWebId = 1;

  Future<List<Note>> fetchNotes() async {
    if (kIsWeb) {
      final list = List<Note>.from(_webNotes);
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    }

    final db = await _openDb();
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> addNote({required String title, String body = ''}) async {
    final note = Note(
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );

    if (kIsWeb) {
      final created = Note(
        id: _nextWebId++,
        title: note.title,
        body: note.body,
        updatedAt: note.updatedAt,
        dirty: true,
      );
      _webNotes.add(created);
      return created;
    }

    final db = await _openDb();
    final id = await db.insert('notes', note.toMap());
    return Note(
      id: id,
      title: note.title,
      body: note.body,
      updatedAt: note.updatedAt,
      dirty: true,
    );
  }

  Future<Note> updateNote({
    required int id,
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: id,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
      dirty: true,
    );

    if (kIsWeb) {
      final idx = _webNotes.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _webNotes[idx] = note;
      }
      return note;
    }

    final db = await _openDb();
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    return note;
  }

  Future<void> deleteNote(int id) async {
    if (kIsWeb) {
      _webNotes.removeWhere((n) => n.id == id);
      return;
    }

    final db = await _openDb();
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countDirty() async {
    if (kIsWeb) {
      return _webNotes.where((n) => n.dirty).length;
    }

    final db = await _openDb();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM notes WHERE dirty = 1',
    );
    return ((rows.first['c'] as num?)?.toInt() ?? 0);
  }

  Future<void> markAllSynced() async {
    if (kIsWeb) {
      for (var i = 0; i < _webNotes.length; i++) {
        if (_webNotes[i].dirty) {
          _webNotes[i] = _webNotes[i].copyWith(dirty: false);
        }
      }
      return;
    }

    final db = await _openDb();
    await db.update('notes', {'dirty': 0}, where: 'dirty = 1');
  }
}