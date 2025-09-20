import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/connectivity_service.dart';

class ConnectivityBanner extends StatefulWidget {
  final ConnectivityStatus status;
  final VoidCallback? onRetry;
  
  const ConnectivityBanner({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
    // Only show banner when offline
    if (widget.status == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.lightStatusWarning,
              AppColors.lightStatusWarning.withValues(alpha: 0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightStatusWarning.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.status == ConnectivityStatus.checking 
                      ? Icons.wifi_find 
                      : Icons.wifi_off,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.status == ConnectivityStatus.checking 
                          ? 'Vérification de la connexion...' 
                          : 'Mode hors ligne',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.status == ConnectivityStatus.checking
                          ? 'Tentative de reconnexion en cours'
                          : 'Vos données seront synchronisées dès la reconnexion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: widget.onRetry != null
                    ? GestureDetector(
                        onTap: widget.onRetry,
                        child: Icon(
                          widget.status == ConnectivityStatus.checking 
                              ? Icons.sync 
                              : Icons.refresh,
                          color: Colors.white,
                          size: 16,
                        ),
                      )
                    : Icon(
                        widget.status == ConnectivityStatus.checking 
                            ? Icons.sync 
                            : Icons.sync_disabled,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}