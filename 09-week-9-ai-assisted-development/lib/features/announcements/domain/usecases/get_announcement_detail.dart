import '../../../../core/failures.dart';
import '../entities/announcement.dart';
import '../repositories/announcement_repository.dart';

class GetAnnouncementDetail {
  const GetAnnouncementDetail(this._repository);
  final AnnouncementRepository _repository;

  Future<({Announcement? announcement, Failure? failure})> call(int id) {
    if (id <= 0) {
      return Future.value((
        announcement: null,
        failure: const ValidationFailure('ID pengumuman tidak valid'),
      ));
    }
    return _repository.getAnnouncementById(id);
  }
}
