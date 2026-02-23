// lib/widgets/custom_text_field.dart
// Reusable themed text field used across all forms in the app.

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? helperText;
  final int maxLines;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.validator,
    this.helperText,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.primary, size: 22)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}