import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/constants/app_colors.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isSecondary;

  const GlassButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.backgroundColor,
    this.textColor = Colors.black,
    this.height = 54.0,
    this.width,
    this.borderRadius = 16.0,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = isSecondary
        ? null
        : (gradient ?? AppColors.primaryGradient);

    final effectiveColor = isSecondary
        ? (backgroundColor ?? AppColors.glassSurfaceHighlight)
        : (gradient == null && backgroundColor != null ? backgroundColor : null);

    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isSecondary
            ? Border.all(color: AppColors.glassBorder, width: 1.2)
            : null,
        boxShadow: isSecondary
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          splashColor: Colors.white.withOpacity(0.2),
          child: Center(
            child: isLoading
                ? const SpinKitThreeBounce(
                    color: Colors.black,
                    size: 24,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          color: isSecondary ? AppColors.textPrimary : textColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: isSecondary ? AppColors.textPrimary : textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
