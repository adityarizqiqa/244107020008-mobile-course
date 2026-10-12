import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/get_announcement_detail.dart';
import '../../domain/usecases/get_announcements.dart';

// Data Layer DI
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepositoryImpl();
});

// Domain Layer DI
final getAnnouncementsUseCaseProvider = Provider<GetAnnouncements>((ref) {
  return GetAnnouncements(ref.watch(announcementRepositoryProvider));
});

final getAnnouncementDetailUseCaseProvider = Provider<GetAnnouncementDetail>((ref) {
  return GetAnnouncementDetail(ref.watch(announcementRepositoryProvider));
});

// Presentation Layer State
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(getAnnouncementsUseCaseProvider).call();
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  return result.announcements;
});

final announcementDetailProvider =
    FutureProvider.family<Announcement, int>((ref, id) async {
  final result = await ref.watch(getAnnouncementDetailUseCaseProvider).call(id);
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  if (result.announcement == null) {
    throw Exception('Pengumuman tidak ditemukan');
  }
  return result.announcement!;
});
