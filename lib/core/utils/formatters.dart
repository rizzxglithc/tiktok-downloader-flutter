import 'dart:math';
import 'package:intl/intl.dart';

class Formatters {
  /// Format bytes to human readable string (KB, MB, GB)
  static String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final value = bytes / pow(1024, i);
    return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format duration in seconds to MM:SS or HH:MM:SS
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '00:00';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = secs.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minStr:$secStr';
    }
    return '$minStr:$secStr';
  }

  /// Format big numbers (Likes, Views, Shares) into K, M, B format
  static String formatCompactNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    if (number < 1000000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  }

  /// Format timestamp into readable date
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Relative date string (e.g. Hari ini, Kemarin, dll)
  static String formatRelativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays == 0) return 'Hari ini, ${DateFormat('HH:mm').format(dateTime)}';
    if (diff.inDays == 1) return 'Kemarin, ${DateFormat('HH:mm').format(dateTime)}';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
