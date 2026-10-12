import 'package:clean_architecture/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Format & Parsing Pure Function Tests', () {
    test('formatDate memformat DateTime dengan padding nol yang tepat', () {
      final dt = DateTime(2026, 9, 5, 8, 4);
      final formatted = formatDate(dt);
      expect(formatted, '2026-09-05 08:04');
    });

    test('formatRelativeDate menghasilkan teks waktu relatif yang benar', () {
      final base = DateTime(2026, 10, 12, 12, 0, 0);

      final justNow = base.subtract(const Duration(seconds: 30));
      expect(formatRelativeDate(justNow, now: base), 'Baru saja');

      final minutesAgo = base.subtract(const Duration(minutes: 15));
      expect(formatRelativeDate(minutesAgo, now: base), '15 menit lalu');

      final hoursAgo = base.subtract(const Duration(hours: 3));
      expect(formatRelativeDate(hoursAgo, now: base), '3 jam lalu');

      final yesterday = base.subtract(const Duration(days: 1));
      expect(formatRelativeDate(yesterday, now: base), 'Kemarin');

      final daysAgo = base.subtract(const Duration(days: 4));
      expect(formatRelativeDate(daysAgo, now: base), '4 hari lalu');
    });

    test('parseIdFromRoute mengekstrak ID integer dari rute', () {
      expect(parseIdFromRoute('/announcements/42'), 42);
      expect(parseIdFromRoute('/notes/100'), 100);
      expect(parseIdFromRoute('/invalid/abc'), isNull);
      expect(parseIdFromRoute('/'), isNull);
    });

    test('parseRouteParam mengekstrak nilai placeholder dengan tepat', () {
      expect(
        parseRouteParam('/announcements/99', '/announcements/:id', 'id'),
        '99',
      );
      expect(
        parseRouteParam('/notes/456', '/notes/:noteId', 'noteId'),
        '456',
      );
      expect(
        parseRouteParam('/other/123/extra', '/other/:id', 'id'),
        isNull,
      );
    });
  });
}
