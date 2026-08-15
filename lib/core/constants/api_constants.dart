class ApiConstants {
  // Primary Endpoint: TikWM API
  static const String tikwmBaseUrl = 'https://www.tikwm.com/api/';
  
  // Backup / Fallback Endpoints
  static const String tikwmBackupUrl = 'https://tikwm.com/api/';

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration downloadTimeout = Duration(minutes: 5);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
  };
}
