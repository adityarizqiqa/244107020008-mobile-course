import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/format.dart';
import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final dirtyCountState = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Bersih (Clean Arch)'),
        actions: [
          IconButton(
            tooltip: 'Sinkronisasi Catatan',
            icon: Badge(
              isLabelVisible: (dirtyCountState.value ?? 0) > 0,
              label: Text('${dirtyCountState.value ?? 0}'),
              child: const Icon(Icons.sync),
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final syncResult = await ref.read(syncNotesUseCaseProvider).call();
              if (syncResult.failure != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(syncResult.failure!.message),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              } else {
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('${syncResult.syncedCount} catatan berhasil disinkronkan!'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(notesProvider);
              ref.invalidate(dirtyCountProvider);
            },
          ),
        ],
      ),
      body: notesState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Terjadi Kesalahan:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(notesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (notes) => notes.isEmpty
            ? Center(
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
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notes.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            if (note.dirty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade700),
                                ),
                                child: Text(
                                  'Unsynced',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                note.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              formatRelativeDate(note.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showNoteDialog(context, ref, note: note);
                            } else if (value == 'delete') {
                              _confirmDelete(context, ref, note);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Hapus', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, {Note? note}) {
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.body ?? '');
    final isEditing = note != null;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isEditing ? 'Edit Catatan' : 'Tambah Catatan Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(dialogCtx);

              if (isEditing) {
                final result = await ref.read(updateNoteUseCaseProvider).call(
                      id: note.id!,
                      title: titleController.text,
                      body: bodyController.text,
                    );
                if (result.failure != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(result.failure!.message)),
                  );
                } else {
                  nav.pop();
                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                }
              } else {
                final result = await ref.read(addNoteUseCaseProvider).call(
                      title: titleController.text,
                      body: bodyController.text,
                    );
                if (result.failure != null) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(result.failure!.message)),
                  );
                } else {
                  nav.pop();
                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);
                }
              }
            },
            child: Text(isEditing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Apakah Anda yakin ingin menghapus "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final nav = Navigator.of(dialogCtx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final result = await ref.read(deleteNoteUseCaseProvider).call(note.id!);
              nav.pop();
              if (result.failure != null) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(result.failure!.message)),
                );
              } else {
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Catatan berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
