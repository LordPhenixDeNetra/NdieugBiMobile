import 'package:flutter/material.dart';

class CustomErrorWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onRetry;
  final Widget? customAction;
  final bool showDetails;
  final String? details;
  final Color? iconColor;

  const CustomErrorWidget({
    Key? key,
    required this.title,
    required this.message,
    this.icon,
    this.actionText,
    this.onRetry,
    this.customAction,
    this.showDetails = false,
    this.details,
    this.iconColor,
  }) : super(key: key);

  @override
  State<CustomErrorWidget> createState() => _CustomErrorWidgetState();
}

class _CustomErrorWidgetState extends State<CustomErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (widget.iconColor ?? colorScheme.error).withValues(alpha: 0.1),
                      border: Border.all(
                        color: (widget.iconColor ?? colorScheme.error).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.icon ?? Icons.error_outline,
                      size: 48,
                      color: widget.iconColor ?? colorScheme.error,
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
                  widget.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.showDetails && widget.details != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    icon: Icon(
                      _showDetails ? Icons.expand_less : Icons.expand_more,
                    ),
                    label: Text(_showDetails ? 'Masquer les détails' : 'Voir les détails'),
                  ),
                  if (_showDetails) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        widget.details!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 32),
                if (widget.customAction != null)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: widget.customAction!,
                  )
                else if (widget.onRetry != null)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(widget.actionText ?? 'Réessayer'),
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

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    Key? key,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      icon: Icons.wifi_off,
      title: 'Problème de connexion',
      message: 'Vérifiez votre connexion internet et réessayez',
      onRetry: onRetry,
      iconColor: Colors.orange,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? details;

  const ServerErrorWidget({
    Key? key,
    this.onRetry,
    this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      icon: Icons.cloud_off,
      title: 'Erreur du serveur',
      message: 'Une erreur s\'est produite sur le serveur. Veuillez réessayer plus tard.',
      onRetry: onRetry,
      showDetails: details != null,
      details: details,
      iconColor: Colors.red,
    );
  }
}

class NotFoundErrorWidget extends StatelessWidget {
  final String itemType;
  final VoidCallback? onGoBack;

  const NotFoundErrorWidget({
    Key? key,
    required this.itemType,
    this.onGoBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      icon: Icons.search_off,
      title: '$itemType introuvable',
      message: 'L\'élément que vous recherchez n\'existe pas ou a été supprimé.',
      actionText: 'Retour',
      onRetry: onGoBack,
      iconColor: Colors.grey,
    );
  }
}