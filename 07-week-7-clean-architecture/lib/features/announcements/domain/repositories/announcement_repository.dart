import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Abstract contract for Announcement repository in Domain layer
abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements();
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(int id);
}
