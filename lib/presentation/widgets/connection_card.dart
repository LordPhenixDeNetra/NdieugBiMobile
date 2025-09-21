import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/connection.dart';
import '../providers/theme_provider.dart';

class ConnectionCard extends StatelessWidget {
  final Connection connection;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTest;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const ConnectionCard({
    super.key,
    required this.connection,
    this.onEdit,
    this.onDelete,
    this.onTest,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getTypeIcon(),
                    color: _getTypeColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        connection.type.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (connection.description?.isNotEmpty == true) ...[
              Text(
                connection.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            _buildConnectionDetails(context, isDark),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onTest != null)
                  TextButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Tester'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightStatusInfo,
                    ),
                  ),
                if (connection.isConnected && onDisconnect != null)
                  TextButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off, size: 16),
                    label: const Text('Déconnecter'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightStatusWarning,
                    ),
                  ),
                if (!connection.isConnected && onConnect != null)
                  TextButton.icon(
                    onPressed: onConnect,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Connecter'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightStatusSuccess,
                    ),
                  ),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightAccentPrimary,
                    ),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightStatusError,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDetails(BuildContext context, bool isDark) {
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    
    switch (connection.type.toLowerCase()) {
      case 'bluetooth':
        return Row(
          children: [
            Icon(Icons.bluetooth, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              connection.address ?? 'Adresse inconnue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
            ),
            const Spacer(),
            if (connection.signalStrength != null) ...[
              Icon(Icons.signal_cellular_alt, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                '${connection.signalStrength}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ],
          ],
        );
      case 'wifi':
        return Row(
          children: [
            Icon(Icons.wifi, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              connection.ssid ?? 'SSID inconnu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
            ),
            const Spacer(),
            if (connection.signalStrength != null) ...[
              Icon(Icons.signal_wifi_4_bar, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                '${connection.signalStrength}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ],
          ],
        );
      case 'api':
        return Row(
          children: [
            Icon(Icons.api, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              connection.endpoint ?? 'Endpoint inconnu',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
            ),
            const Spacer(),
            if (connection.lastPing != null) ...[
              Icon(Icons.access_time, size: 16, color: textColor),
              const SizedBox(width: 4),
              Text(
                _formatLastPing(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ],
          ],
        );
      default:
        return Row(
          children: [
            Icon(Icons.device_unknown, size: 16, color: textColor),
            const SizedBox(width: 4),
            Text(
              'Connexion générique',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ],
        );
    }
  }

  IconData _getTypeIcon() {
    switch (connection.type.toLowerCase()) {
      case 'bluetooth':
        return Icons.bluetooth;
      case 'wifi':
        return Icons.wifi;
      case 'api':
        return Icons.api;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getTypeColor() {
    switch (connection.type.toLowerCase()) {
      case 'bluetooth':
        return AppColors.lightAccentPrimary;
      case 'wifi':
        return AppColors.lightAccentSecondary;
      case 'api':
        return AppColors.lightStatusInfo;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  Color _getStatusColor() {
    if (connection.isConnected) {
      return AppColors.lightStatusSuccess;
    } else if (connection.isActive) {
      return AppColors.lightStatusWarning;
    } else {
      return AppColors.lightStatusError;
    }
  }

  String _getStatusText() {
    if (connection.isConnected) {
      return 'Connecté';
    } else if (connection.isActive) {
      return 'Disponible';
    } else {
      return 'Déconnecté';
    }
  }

  String _formatLastPing() {
    if (connection.lastPing == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(connection.lastPing!);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else {
      return '${difference.inHours}h';
    }
  }
}