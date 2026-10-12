import 'package:dio/dio.dart';
import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  AnnouncementRepositoryImpl({Dio? dioClient}) : _dio = dioClient ?? Dio();

  // ignore: unused_field
  final Dio _dio;

  // Fallback / mock dataset yang mencerminkan sistem pengumuman akademik JTI Polinema
  static final List<AnnouncementModel> _seedAnnouncements = [
    AnnouncementModel(
      id: 1,
      title: 'Jadwal Ujian Tengah Semester Ganjil 2026/2027',
      content:
          'Diberitahukan kepada seluruh mahasiswa Jurusan Teknologi Informasi bahwa UTS akan dilaksanakan secara luring mulai tanggal 19 Oktober 2026. Harap mengecek kartu ujian di SIAKAD.',
      publishedAt: DateTime(2026, 10, 10, 8, 30),
      author: 'Bagian Akademik JTI',
      category: 'Akademik',
    ),
    AnnouncementModel(
      id: 2,
      title: 'Pendaftaran Workshop Clean Architecture & Flutter Riverpod',
      content:
          'Lab Mobile Programming menyelenggarakan workshop praktis Clean Architecture, State Management, dan Unit Testing. Tempat terbatas untuk 40 pendaftar pertama.',
      publishedAt: DateTime(2026, 10, 11, 13, 15),
      author: 'Lab Pemrograman Mobile',
      category: 'Workshop',
    ),
    AnnouncementModel(
      id: 3,
      title: 'Pemeliharaan Server SIAKAD & E-Learning',
      content:
          'Server e-learning dan SIAKAD Polinema akan mengalami downtime terjadwal pada hari Sabtu pukul 22:00 - 04:00 WIB untuk pemeliharaan berkala infrastruktur database.',
      publishedAt: DateTime(2026, 10, 12, 10, 0),
      author: 'UPT Komputer & Jaringan',
      category: 'Pemeliharaan',
    ),
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})> getAnnouncements() async {
    try {
      // Mensimulasikan network delay realistis
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final list = _seedAnnouncements.map((m) => m.toEntity()).toList();
      return (announcements: list, failure: null);
    } catch (e) {
      return (
        announcements: const <Announcement>[],
        failure: NetworkFailure('Gagal memuat pengumuman: $e'),
      );
    }
  }

  @override
  Future<({Announcement? announcement, Failure? failure})> getAnnouncementById(int id) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final found = _seedAnnouncements.where((m) => m.id == id);
      if (found.isEmpty) {
        return (
          announcement: null,
          failure: NotFoundFailure('Pengumuman dengan ID $id tidak ditemukan.'),
        );
      }
      return (announcement: found.first.toEntity(), failure: null);
    } catch (e) {
      return (
        announcement: null,
        failure: NetworkFailure('Gagal membaca detail pengumuman: $e'),
      );
    }
  }
}
