import 'package:flutter/material.dart';

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final EdgeInsetsGeometry? padding;

  const FilterChipWidget({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final effectiveSelectedColor = selectedColor ?? colorScheme.primary;
    final effectiveUnselectedColor = unselectedColor ?? colorScheme.surfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: effectiveUnselectedColor,
        selectedColor: effectiveSelectedColor,
        checkmarkColor: colorScheme.onPrimary,
        side: BorderSide(
          color: isSelected 
              ? effectiveSelectedColor 
              : colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: padding ?? const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: isSelected ? 2 : 0,
        shadowColor: effectiveSelectedColor.withValues(alpha: 0.3),
      ),
    );
  }
}