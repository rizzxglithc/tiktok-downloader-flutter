import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/app_exceptions.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final appException = _mapDioErrorToAppException(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: appException,
              message: appException.message,
              type: e.type,
              response: e.response,
            ),
          );
        },
      ),
    );
  }

  static AppException _mapDioErrorToAppException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException('Waktu koneksi habis. Silakan periksa jaringan internet Anda.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return const ApiException('Video TikTok tidak ditemukan atau telah dihapus/private.');
        } else if (statusCode == 429) {
          return const ApiException('Terlalu banyak permintaan ke server TikTok. Tunggu beberapa saat.');
        } else if (statusCode != null && statusCode >= 500) {
          return const ApiException('Server TikTok downloader sedang sibuk. Silakan coba lagi.');
        }
        return ApiException('Gagal memproses video (Status: $statusCode).');
      case DioExceptionType.cancel:
        return const DownloadException('Permintaan atau pengunduhan dibatalkan.');
      default:
        return const ApiException('Terjadi kesalahan saat memproses URL TikTok.');
    }
  }
}
