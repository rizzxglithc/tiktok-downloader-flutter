import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool autofocus;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onClear,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.url,
    this.textInputAction = TextInputAction.done,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.border,
              width: 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofocus: autofocus,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            cursorColor: AppColors.textPrimary,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: InputBorder.none,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon ??
                  (controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                          onPressed: () {
                            controller.clear();
                            onClear?.call();
                          },
                        )
                      : null),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
