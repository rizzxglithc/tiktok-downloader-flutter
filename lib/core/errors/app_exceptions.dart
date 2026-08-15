abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Koneksi internet bermasalah. Periksa jaringan Anda.'])
      : super(message, code: 'NETWORK_ERROR');
}

class ApiException extends AppException {
  const ApiException([String message = 'Gagal mengambil data video dari server TikTok.'])
      : super(message, code: 'API_ERROR');
}

class ValidationException extends AppException {
  const ValidationException(String message)
      : super(message, code: 'VALIDATION_ERROR');
}

class DownloadException extends AppException {
  const DownloadException([String message = 'Proses pengunduhan gagal.'])
      : super(message, code: 'DOWNLOAD_ERROR');
}

class StorageException extends AppException {
  const StorageException([String message = 'Gagal menyimpan file ke penyimpanan perangkat.'])
      : super(message, code: 'STORAGE_ERROR');
}

class PermissionException extends AppException {
  const PermissionException([String message = 'Izin penyimpanan dibutuhkan untuk menyimpan video/audio.'])
      : super(message, code: 'PERMISSION_DENIED');
}
