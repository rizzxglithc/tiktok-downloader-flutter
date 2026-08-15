import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ToastType { success, error, info, warning }

class CustomToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    Color iconColor;
    IconData iconData;
    LinearGradient gradient;

    switch (type) {
      case ToastType.success:
        iconColor = AppColors.success;
        iconData = Icons.check_circle_rounded;
        gradient = LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.2),
            AppColors.surface.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case ToastType.error:
        iconColor = AppColors.error;
        iconData = Icons.error_rounded;
        gradient = LinearGradient(
          colors: [
            AppColors.error.withOpacity(0.2),
            AppColors.surface.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case ToastType.warning:
        iconColor = AppColors.warning;
        iconData = Icons.warning_amber_rounded;
        gradient = LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.2),
            AppColors.surface.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
      case ToastType.info:
      default:
        iconColor = AppColors.primary;
        iconData = Icons.info_rounded;
        gradient = LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.surface.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * -20),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iconColor.withOpacity(0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, color: iconColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
