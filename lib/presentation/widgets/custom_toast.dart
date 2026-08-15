import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomToast {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_rounded, Colors.white, Colors.black);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Icons.error_outline_rounded, AppColors.error, Colors.white);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, Icons.info_outline_rounded, Colors.white, Colors.black);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color accentColor,
    Color textColor,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
