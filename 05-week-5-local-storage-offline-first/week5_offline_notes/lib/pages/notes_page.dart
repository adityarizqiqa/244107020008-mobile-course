import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import '../data/sync.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  void _showAddEditNoteDialog(
    BuildContext context,
    WidgetRef ref, {
    Note? existingNote,
  }) {
    final titleController = TextEditingController(text: existingNote?.title ?? '');
    final bodyController = TextEditingController(text: existingNote?.body ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existingNote == null ? 'Tambah Catatan Baru' : 'Edit Catatan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Judul Catatan',
                    hintText: 'Masukkan judul...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Catatan',
                    hintText: 'Tulis isi catatan Anda di sini...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Judul catatan tidak boleh kosong')),
                  );
                  return;
                }

                try {
                  final repo = ref.read(noteRepositoryProvider);
                  if (existingNote == null) {
                    await repo.addNote(title: title, body: body);
                  } else {
                    await repo.updateNote(
                      id: existingNote.id!,
                      title: title,
                      body: body,
                    );
                  }

                  ref.invalidate(notesProvider);
                  ref.invalidate(dirtyCountProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(existingNote == null
                            ? 'Catatan berhasil ditambahkan'
                            : 'Catatan berhasil diperbarui'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan catatan: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    final isOffline = ref.read(forceOfflineProvider);
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulasi Offline aktif! Matikan toggle offline terlebih dahulu untuk sync.'),
          backgroundColor: Colors.deepOrange,
        ),
      );
      return;
    }

    ref.read(isSyncingProvider.notifier).set(true);
    try {
      final repo = ref.read(noteRepositoryProvider);
      final syncedCount = await syncNotes(repo);

      ref.invalidate(notesProvider);
      ref.invalidate(dirtyCountProvider);
      ref.read(lastSyncTimeProvider.notifier).update(DateTime.now());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncedCount > 0
                  ? 'Berhasil menyinkronkan $syncedCount catatan ke server (dirty -> 0)!'
                  : 'Semua catatan sudah tersinkron (tidak ada catatan dirty).',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      ref.read(isSyncingProvider.notifier).set(false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyCountAsync = ref.watch(dirtyCountProvider);
    final isOffline = ref.watch(forceOfflineProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    final dirtyCount = dirtyCountAsync.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          // Indikator Badge Dirty
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: Icon(
                dirtyCount > 0 ? Icons.cloud_upload : Icons.cloud_done,
                size: 16,
                color: dirtyCount > 0 ? Colors.orange.shade800 : Colors.green.shade800,
              ),
              label: Text(
                '$dirtyCount dirty',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: dirtyCount > 0 ? Colors.orange.shade900 : Colors.green.shade900,
                ),
              ),
              backgroundColor: dirtyCount > 0
                  ? Colors.orange.shade100
                  : Colors.green.shade100,
              side: BorderSide.none,
            ),
          ),
          // Tombol Sinkronisasi
          IconButton(
            tooltip: 'Sinkronisasi Catatan',
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: isSyncing ? null : () => _handleSync(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Deterministic Offline Toggle Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isOffline
                ? Colors.amber.shade100
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.airplanemode_active : Icons.wifi,
                  color: isOffline ? Colors.amber.shade900 : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOffline ? 'Simulasi Offline (Aktif)' : 'Simulasi Offline (Nonaktif)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOffline ? Colors.amber.shade900 : Colors.black87,
                        ),
                      ),
                      Text(
                        isOffline
                            ? 'Aplikasi berjalan offline lokal tanpa akses jaringan'
                            : 'Koneksi siap untuk sinkronisasi catatan',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOffline ? Colors.amber.shade900 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isOffline,
                  onChanged: (val) {
                    ref.read(forceOfflineProvider.notifier).set(val);
                  },
                ),
              ],
            ),
          ),
          // Daftar Catatan
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Catatan',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Catatan tersimpan di SQLite lokal perangkat Anda dan tetap bisa dibaca saat offline.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: notes.length,
                  itemBuilder: (ctx, index) {
                    final note = notes[index];
                    return NoteTile(
                      note: note,
                      onTap: () => _showAddEditNoteDialog(
                        context,
                        ref,
                        existingNote: note,
                      ),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Hapus Catatan?'),
                            content: Text('Yakin ingin menghapus "${note.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && note.id != null) {
                          await ref.read(noteRepositoryProvider).deleteNote(note.id!);
                          ref.invalidate(notesProvider);
                          ref.invalidate(dirtyCountProvider);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Gagal memuat catatan: $err'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(notesProvider),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditNoteDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
      ),
    );
  }
}

/// Widget NoteTile mandiri hasil Refactoring Challenge
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final updated = note.updatedAt.toLocal();
    final dateStr =
        '${updated.day.toString().padLeft(2, '0')}/${updated.month.toString().padLeft(2, '0')} ${updated.hour.toString().padLeft(2, '0')}:${updated.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: note.dirty
              ? Colors.orange.shade300
              : Theme.of(context).colorScheme.outlineVariant,
          width: note.dirty ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge dirty flag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: note.dirty
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note.dirty
                              ? Icons.sync_problem_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 13,
                          color: note.dirty
                              ? Colors.orange.shade900
                              : Colors.green.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.dirty ? 'Belum Sync' : 'Tersinkron',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: note.dirty
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Diperbarui: $dateStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red.shade400,
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
