import 'package:flutter/material.dart';

class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? customAction;
  final Color? iconColor;
  final double? iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.customAction,
    this.iconColor,
    this.iconSize,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (widget.iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                      border: Border.all(
                        color: (widget.iconColor ?? colorScheme.primary).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: widget.iconSize ?? 48,
                      color: widget.iconColor ?? colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (widget.customAction != null)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: widget.customAction!,
                  )
                else if (widget.actionText != null && widget.onAction != null)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton.icon(
                      onPressed: widget.onAction,
                      icon: const Icon(Icons.add),
                      label: Text(widget.actionText!),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

class EmptySearchWidget extends StatelessWidget {
  final String searchQuery;
  final VoidCallback? onClearSearch;

  const EmptySearchWidget({
    Key? key,
    required this.searchQuery,
    this.onClearSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Aucun résultat trouvé',
      subtitle: 'Aucun élément ne correspond à "$searchQuery"',
      actionText: 'Effacer la recherche',
      onAction: onClearSearch,
    );
  }
}

class EmptyListWidget extends StatelessWidget {
  final String itemType;
  final VoidCallback? onAdd;

  const EmptyListWidget({
    Key? key,
    required this.itemType,
    this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.inbox_outlined,
      title: 'Aucun $itemType',
      subtitle: 'Commencez par ajouter des ${itemType}s',
      actionText: 'Ajouter $itemType',
      onAction: onAdd,
    );
  }
}