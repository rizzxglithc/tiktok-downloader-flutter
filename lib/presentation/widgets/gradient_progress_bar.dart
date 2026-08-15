import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final double borderRadius;
  final Color? backgroundColor;

  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 6.0,
    this.borderRadius = 8.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceHover,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedProgress,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
