import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(searchQueryProvider, (_, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    });

    final notesState = ref.watch(filteredNotesProvider);
    final dirtyCount = ref.watch(dirtyCountProvider).value ?? 0;
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Notes'),
        actions: _buildAppBarActions(context, dirtyCount),
      ),
      body: Column(
        children: [
          _buildSearchBar(query),
          Expanded(child: _buildBody(notesState, query)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, int dirtyCount) {
    return [
      IconButton(
        tooltip: 'Sinkronisasi Catatan',
        icon: Badge(
          isLabelVisible: dirtyCount > 0,
          label: Text('$dirtyCount'),
          child: const Icon(Icons.sync),
        ),
        onPressed: () => _handleSync(context),
      ),
      IconButton(
        tooltip: 'Muat Ulang',
        icon: const Icon(Icons.refresh),
        onPressed: () {
          ref.invalidate(notesProvider);
          ref.invalidate(dirtyCountProvider);
        },
      ),
    ];
  }

  Widget _buildSearchBar(String query) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        key: const Key('notes_search_field'),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari catatan berdasarkan judul...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  key: const Key('notes_search_clear_button'),
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).clear();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).setQuery(value);
        },
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<Note>> notesState, String query) {
    return notesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Terjadi Kesalahan:\n$e', textAlign: TextAlign.center),
      ),
      data: (notes) {
        if (notes.isEmpty) {
          return _buildEmptyState(query);
        }
        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildEmptyState(String query) {
    if (query.trim().isNotEmpty) {
      return _buildSearchEmptyState(query);
    }
    return _buildInitialEmptyState();
  }

  Widget _buildSearchEmptyState(String query) {
    return Center(
      key: const Key('notes_search_empty_state'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada catatan ditemukan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada hasil untuk "$query"',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).clear();
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Reset Pencarian'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Belum ada catatan.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tekan tombol + di bawah untuk menambah catatan baru.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notesProvider);
        ref.invalidate(dirtyCountProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildNoteCard(context, notes[index]),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.body.isNotEmpty)
              Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              formatRelativeDate(note.updatedAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) {
            if (val == 'edit') _showNoteDialog(context, note: note);
            if (val == 'delete') _confirmDelete(context, note);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSync(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final syncResult = await ref.read(syncNotesUseCaseProvider).call();
    if (syncResult.failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(syncResult.failure!.message)),
      );
      return;
    }
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${syncResult.syncedCount} catatan berhasil disinkronkan!',
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, {Note? note}) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final bodyCtrl = TextEditingController(text: note?.body ?? '');
    final isEditing = note != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Catatan' : 'Tambah Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Isi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                _handleNoteSubmit(ctx, note, titleCtrl.text, bodyCtrl.text),
            child: Text(isEditing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNoteSubmit(
    BuildContext ctx,
    Note? note,
    String title,
    String body,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = note != null
        ? await ref
              .read(updateNoteUseCaseProvider)
              .call(id: note.id!, title: title, body: body)
        : await ref.read(addNoteUseCaseProvider).call(title: title, body: body);

    if (result.failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.failure!.message)));
      return;
    }
    if (ctx.mounted) Navigator.pop(ctx);
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
  }

  void _confirmDelete(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeDelete(note.id!);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(deleteNoteUseCaseProvider).call(id);
    if (result.failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.failure!.message)));
      return;
    }
    ref.invalidate(notesProvider);
    ref.invalidate(dirtyCountProvider);
    messenger.showSnackBar(
      const SnackBar(content: Text('Catatan berhasil dihapus')),
    );
  }
}
