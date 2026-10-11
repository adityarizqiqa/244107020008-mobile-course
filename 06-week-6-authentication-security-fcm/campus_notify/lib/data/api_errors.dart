import 'package:dio/dio.dart';

String readableApiError(dynamic error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Gagal terhubung ke server (offline). Pastikan koneksi internet aktif.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Sesi login telah kedaluwarsa. Silakan masuk kembali.';
        } else if (statusCode == 403) {
          return 'Akses ditolak. Anda tidak memiliki izin.';
        } else if (statusCode == 404) {
          return 'Data yang diminta tidak ditemukan.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server sedang mengalami gangguan (Error $statusCode).';
        }
        return 'Terjadi kesalahan pada server (Status: $statusCode).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      default:
        return 'Terjadi kesalahan jaringan: ${error.message ?? 'Unknown error'}';
    }
  }
  return error?.toString() ?? 'Terjadi kesalahan yang tidak diketahui.';
}
