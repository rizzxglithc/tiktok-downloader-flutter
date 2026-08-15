import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;

  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: constraints.maxWidth * clampedProgress,
              height: height,
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
