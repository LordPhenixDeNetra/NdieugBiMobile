import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lightAccentPrimary,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? elevation;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.lightAccentPrimary,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        elevation: elevation ?? 2,
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                child,
              ],
            )
          : child,
    );
  }
}

class LoadingCard extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? loadingMessage;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LoadingCard({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingMessage,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: margin ?? const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lightAccentPrimary,
                        ),
                      ),
                      if (loadingMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          loadingMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoadingListTile extends StatelessWidget {
  final bool isLoading;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? loadingMessage;

  const LoadingListTile({
    super.key,
    required this.isLoading,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Stack(
      children: [
        ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          onTap: isLoading ? null : onTap,
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                  .withValues(alpha: 0.8),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.lightAccentPrimary,
                        ),
                      ),
                    ),
                    if (loadingMessage != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        loadingMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}