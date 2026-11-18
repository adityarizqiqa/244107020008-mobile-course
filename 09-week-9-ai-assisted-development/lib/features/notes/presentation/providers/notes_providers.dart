import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/note_db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes.dart';
import '../../domain/usecases/sync_notes.dart';
import '../../domain/usecases/update_note.dart';

// ---------------------------------------------------------
// DATA LAYER DI: Database opener disuntikkan ke repository
// ---------------------------------------------------------
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// ---------------------------------------------------------
// DOMAIN LAYER DI: Use case menerima abstraksi interface repository
// ---------------------------------------------------------
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteUseCaseProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

final updateNoteUseCaseProvider = Provider<UpdateNote>((ref) {
  return UpdateNote(ref.watch(noteRepositoryProvider));
});

final deleteNoteUseCaseProvider = Provider<DeleteNote>((ref) {
  return DeleteNote(ref.watch(noteRepositoryProvider));
});

final syncNotesUseCaseProvider = Provider<SyncNotes>((ref) {
  return SyncNotes(ref.watch(noteRepositoryProvider));
});

final searchNotesUseCaseProvider = Provider<SearchNotes>((ref) {
  return const SearchNotes();
});

// ---------------------------------------------------------
// PRESENTATION LAYER: State untuk konsumsi Widget UI
// ---------------------------------------------------------
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.notes;
});

/// Notifier to manage real-time search query in Riverpod 3.x
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider);
  final searchNotes = ref.watch(searchNotesUseCaseProvider);

  return notesAsync.whenData((notes) {
    return searchNotes(notes: notes, query: query);
  });
});

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  final result = await repo.countDirty();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.count;
});
