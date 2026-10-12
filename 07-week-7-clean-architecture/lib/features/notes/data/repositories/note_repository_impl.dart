import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.openDb});

  final Future<Database> Function() openDb;

  // In-memory fallback for web environment where sqflite platform channel isn't native
  static final List<NoteModel> _webNotes = [];
  static int _webIdCounter = 1;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    try {
      if (kIsWeb) {
        final list = List<NoteModel>.from(_webNotes)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final notes = list.map((m) => m.toEntity()).toList();
        return (notes: notes, failure: null);
      }

      final db = await openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes: notes, failure: null);
    } catch (e) {
      return (
        notes: const <Note>[],
        failure: LocalFailure('Gagal membaca catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final now = DateTime.now();

      if (kIsWeb) {
        final model = NoteModel(
          id: _webIdCounter++,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        );
        _webNotes.add(model);
        return (note: model.toEntity(), failure: null);
      }

      final db = await openDb();
      final model = NoteModel(
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );
      final id = await db.insert('notes', model.toMap());
      final created = Note(
        id: id,
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );
      return (note: created, failure: null);
    } catch (e) {
      return (
        note: null,
        failure: LocalFailure('Gagal menyimpan catatan: $e'),
      );
    }
  }

  @override
  Future<({Note? note, Failure? failure})> updateNote({
    required int id,
    required String title,
    String body = '',
  }) async {
    try {
      final now = DateTime.now();

      if (kIsWeb) {
        final idx = _webNotes.indexWhere((n) => n.id == id);
        if (idx == -1) {
          return (
            note: null,
            failure: const NotFoundFailure('Catatan tidak ditemukan'),
          );
        }
        final updated = NoteModel(
          id: id,
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        );
        _webNotes[idx] = updated;
        return (note: updated.toEntity(), failure: null);
      }

      final db = await openDb();
      final model = NoteModel(
        id: id,
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );
      final affected = await db.update(
        'notes',
        model.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );

      if (affected == 0) {
        return (
          note: null,
          failure: const NotFoundFailure('Catatan tidak ditemukan'),
        );
      }

      return (note: model.toEntity(), failure: null);
    } catch (e) {
      return (
        note: null,
        failure: LocalFailure('Gagal memperbarui catatan: $e'),
      );
    }
  }

  @override
  Future<({bool success, Failure? failure})> deleteNote(int id) async {
    try {
      if (kIsWeb) {
        _webNotes.removeWhere((n) => n.id == id);
        return (success: true, failure: null);
      }

      final db = await openDb();
      await db.delete('notes', where: 'id = ?', whereArgs: [id]);
      return (success: true, failure: null);
    } catch (e) {
      return (
        success: false,
        failure: LocalFailure('Gagal menghapus catatan: $e'),
      );
    }
  }

  @override
  Future<({int count, Failure? failure})> countDirty() async {
    try {
      if (kIsWeb) {
        final count = _webNotes.where((n) => n.dirty).length;
        return (count: count, failure: null);
      }

      final db = await openDb();
      final rows = await db.rawQuery('SELECT COUNT(*) as cnt FROM notes WHERE dirty = 1');
      final count = (rows.first['cnt'] as num?)?.toInt() ?? 0;
      return (count: count, failure: null);
    } catch (e) {
      return (
        count: 0,
        failure: LocalFailure('Gagal menghitung antrean sync: $e'),
      );
    }
  }

  @override
  Future<({int syncedCount, Failure? failure})> syncNotes() async {
    try {
      if (kIsWeb) {
        var count = 0;
        for (var i = 0; i < _webNotes.length; i++) {
          if (_webNotes[i].dirty) {
            _webNotes[i] = NoteModel(
              id: _webNotes[i].id,
              title: _webNotes[i].title,
              body: _webNotes[i].body,
              updatedAt: _webNotes[i].updatedAt,
              dirty: false,
            );
            count++;
          }
        }
        return (syncedCount: count, failure: null);
      }

      final db = await openDb();
      final affected = await db.update(
        'notes',
        {'dirty': 0},
        where: 'dirty = 1',
      );
      return (syncedCount: affected, failure: null);
    } catch (e) {
      return (
        syncedCount: 0,
        failure: LocalFailure('Gagal melakukan sinkronisasi: $e'),
      );
    }
  }
}
