import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final double height;
  final double? width;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.height = 52.0,
    this.width,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    final bgColor = isSecondary ? AppColors.surfaceElevated : AppColors.primary;
    final fgColor = isSecondary ? AppColors.textPrimary : AppColors.onPrimary;
    final borderColor = isSecondary ? AppColors.borderLight : Colors.transparent;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isEnabled ? 1.0 : 0.45,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isSecondary
              ? []
              : [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: isSecondary ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: fgColor, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
