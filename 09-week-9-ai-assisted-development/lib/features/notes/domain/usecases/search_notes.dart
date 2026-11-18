import '../entities/note.dart';

/// Pure domain use case for filtering notes by title.
class SearchNotes {
  const SearchNotes();

  /// Filters [notes] based on whether [Note.title] contains [query].
  ///
  /// The search is case-insensitive, trims excess whitespace, and returns
  /// the full [notes] list if [query] is empty after trimming.
  List<Note> call({required List<Note> notes, required String query}) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return notes;
    }
    return notes
        .where((note) => note.title.toLowerCase().contains(trimmedQuery))
        .toList();
  }
}
