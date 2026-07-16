import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/tokens.dart';

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.focusNode,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autocorrect;
  final bool enableSuggestions;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final bool autofocus;
  final FocusNode? focusNode;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: TextStyle(color: c.foreground, fontSize: 16, height: 1.25),
      cursorColor: c.primary,
      decoration: InputDecoration(
        hintText: placeholder,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: icon == null ? null : Icon(icon, size: 19, color: c.muted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: c.bgInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 14,
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
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.inputRadius,
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
      ),
    );
    if (label == null) return field;
    final accessibleField = Semantics(label: label, child: field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label!,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: c.foreground),
          ),
        ),
        const SizedBox(height: 7),
        accessibleField,
      ],
    );
  }
}
