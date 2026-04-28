import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.placeholder,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      autofocus: autofocus,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: TextStyle(color: c.textPrimary, fontSize: 15),
      cursorColor: c.accent,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
        prefixIcon:
            icon == null ? null : Icon(icon, size: 18, color: c.textMuted),
        filled: true,
        fillColor: c.bgInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
    );
  }
}
