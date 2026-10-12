// Pure Dart formatting and route parsing utilities (no Flutter/widget dependencies)

/// Memformat objek [DateTime] ke format ringkas YYYY-MM-DD HH:mm
String formatDate(DateTime dateTime) {
  final year = dateTime.year.toString().padLeft(4, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

/// Menghasilkan format tanggal relatif (misal: "Baru saja", "X menit lalu", "Kemarin", dsb.)
String formatRelativeDate(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(dateTime);

  if (difference.isNegative) {
    return formatDate(dateTime);
  }

  if (difference.inSeconds < 60) {
    return 'Baru saja';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} menit lalu';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} jam lalu';
  } else if (difference.inDays == 1) {
    return 'Kemarin';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} hari lalu';
  } else {
    return formatDate(dateTime);
  }
}

/// Mengekstrak ID integer dari segmen path rute (contoh: '/announcements/42' -> 42)
int? parseIdFromRoute(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  return int.tryParse(segments.last);
}

/// Mengekstrak parameter rute berdasarkan kunci placeholder (contoh: pattern '/notes/:id', path '/notes/12' -> 12)
String? parseRouteParam(String path, String pattern, String paramName) {
  final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();
  final patternSegments = pattern.split('/').where((s) => s.isNotEmpty).toList();

  if (pathSegments.length != patternSegments.length) {
    return null;
  }

  final targetToken = ':$paramName';
  for (var i = 0; i < patternSegments.length; i++) {
    if (patternSegments[i] == targetToken) {
      return pathSegments[i];
    }
    if (patternSegments[i] != pathSegments[i]) {
      return null;
    }
  }
  return null;
}
