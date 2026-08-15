class ApiConstants {
  // Primary TikTok API Endpoint (TikWM)
  static const String tikwmBaseUrl = 'https://www.tikwm.com/api/';

  // Fallback API Endpoints
  static const String tiksaveBaseUrl = 'https://api.tiksave.io/v1/download';
  static const String cobaltBaseUrl = 'https://api.cobalt.tools/api/json';

  // Request Headers
  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);
  static const Duration downloadTimeout = Duration(minutes: 5);
}
