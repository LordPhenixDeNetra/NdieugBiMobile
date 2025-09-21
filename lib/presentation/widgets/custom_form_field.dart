import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class CustomFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool required;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final TextEditingController? controller;

  const CustomFormField({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.required = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.controller,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  late TextEditingController _controller;
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (widget.required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: AppColors.lightStatusError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          keyboardType: widget.keyboardType,
          obscureText: _obscureText,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.required && widget.validator == null
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${widget.label} est requis';
                  }
                  return null;
                }
              : widget.validator,
          onChanged: widget.onChanged,
          onSaved: widget.onSaved,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(isDark),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightAccentPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightStatusError,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightStatusError,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.enabled
                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool isDark) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final bool enabled;
  final bool required;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final void Function(T?)? onChanged;
  final void Function(T?)? onSaved;

  const CustomDropdownField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.items,
    this.enabled = true,
    this.required = false,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: AppColors.lightStatusError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          onSaved: onSaved,
          validator: required && validator == null
              ? (value) {
                  if (value == null) {
                    return '$label est requis';
                  }
                  return null;
                }
              : validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  )
                : null,
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightAccentPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightStatusError,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.lightStatusError,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled
                ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ),
      ],
    );
  }
}