import 'package:clean_architecture/core/failures.dart';
import 'package:clean_architecture/features/announcements/domain/entities/announcement.dart';
import 'package:clean_architecture/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:clean_architecture/features/announcements/domain/usecases/get_announcement_detail.dart';
import 'package:clean_architecture/features/announcements/domain/usecases/get_announcements.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({this.items = const [], this.fail = false});

  final List<Announcement> items;
  final bool fail;

  @override
  Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements() async {
    if (fail) {
      return (
        announcements: const <Announcement>[],
        failure: const NetworkFailure('Koneksi timeout'),
      );
    }
    return (announcements: items, failure: null);
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(int id) async {
    if (fail) {
      return (
        announcement: null,
        failure: const NetworkFailure('Koneksi timeout'),
      );
    }
    final found = items.where((a) => a.id == id);
    if (found.isEmpty) {
      return (
        announcement: null,
        failure: const NotFoundFailure('Pengumuman tidak ditemukan'),
      );
    }
    return (announcement: found.first, failure: null);
  }
}

void main() {
  group('Announcement Use Cases Tests', () {
    final sampleItems = [
      Announcement(
        id: 1,
        title: 'UTS Ganjil',
        content: 'Jadwal UTS luring',
        publishedAt: DateTime(2026, 10, 10),
      ),
      Announcement(
        id: 2,
        title: 'Workshop Clean Architecture',
        content: 'Materi Riverpod',
        publishedAt: DateTime(2026, 10, 11),
      ),
    ];

    test('GetAnnouncements mengembalikan seluruh daftar pengumuman', () async {
      final repo = FakeAnnouncementRepository(items: sampleItems);
      final result = await GetAnnouncements(repo).call();

      expect(result.failure, isNull);
      expect(result.announcements.length, 2);
      expect(result.announcements.first.title, 'UTS Ganjil');
    });

    test('GetAnnouncements meneruskan NetworkFailure saat terjadi kegagalan jaringan', () async {
      final repo = FakeAnnouncementRepository(fail: true);
      final result = await GetAnnouncements(repo).call();

      expect(result.failure, isA<NetworkFailure>());
      expect(result.announcements, isEmpty);
    });

    test('GetAnnouncementDetail mengembalikan detail yang cocok dengan ID', () async {
      final repo = FakeAnnouncementRepository(items: sampleItems);
      final result = await GetAnnouncementDetail(repo).call(2);

      expect(result.failure, isNull);
      expect(result.announcement, isNotNull);
      expect(result.announcement!.title, 'Workshop Clean Architecture');
    });

    test('GetAnnouncementDetail menolak ID non-positif dengan ValidationFailure', () async {
      final repo = FakeAnnouncementRepository(items: sampleItems);
      final result = await GetAnnouncementDetail(repo).call(0);

      expect(result.failure, isA<ValidationFailure>());
      expect(result.announcement, isNull);
    });

    test('GetAnnouncementDetail mengembalikan NotFoundFailure jika ID tidak ditemukan', () async {
      final repo = FakeAnnouncementRepository(items: sampleItems);
      final result = await GetAnnouncementDetail(repo).call(999);

      expect(result.failure, isA<NotFoundFailure>());
      expect(result.announcement, isNull);
    });
  });
}
