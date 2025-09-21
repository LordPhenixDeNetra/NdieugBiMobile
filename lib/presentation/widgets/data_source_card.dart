import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/data_source.dart';
import '../../core/theme/app_colors.dart';
import '../providers/theme_provider.dart';

class DataSourceCard extends StatelessWidget {
  final DataSource dataSource;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTest;
  final VoidCallback? onSync;

  const DataSourceCard({
    super.key,
    required this.dataSource,
    this.onEdit,
    this.onDelete,
    this.onTest,
    this.onSync,
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
                        dataSource.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dataSource.type.toUpperCase(),
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
                  child: Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (dataSource.description?.isNotEmpty == true) ...[
              Text(
                dataSource.description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(
                  Icons.storage,
                  size: 16,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${dataSource.host}:${dataSource.port}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                if (dataSource.lastSync != null) ...[
                  Icon(
                    Icons.sync,
                    size: 16,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatLastSync(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
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
                if (onSync != null)
                  TextButton.icon(
                    onPressed: onSync,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync'),
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

  IconData _getTypeIcon() {
    switch (dataSource.type.toLowerCase()) {
      case 'mysql':
        return Icons.storage;
      case 'postgresql':
        return Icons.storage;
      case 'sqlite':
        return Icons.folder;
      case 'mongodb':
        return Icons.account_tree;
      case 'api':
        return Icons.api;
      default:
        return Icons.storage;
    }
  }

  Color _getTypeColor() {
    switch (dataSource.type.toLowerCase()) {
      case 'mysql':
        return AppColors.lightAccentPrimary;
      case 'postgresql':
        return AppColors.lightAccentSecondary;
      case 'sqlite':
        return AppColors.lightStatusSuccess;
      case 'mongodb':
        return AppColors.lightStatusWarning;
      case 'api':
        return AppColors.lightStatusInfo;
      default:
        return AppColors.lightTextSecondary;
    }
  }

  Color _getStatusColor() {
    if (dataSource.isActive) {
      return AppColors.lightStatusSuccess;
    } else {
      return AppColors.lightStatusError;
    }
  }

  String _getStatusText() {
    return dataSource.isActive ? 'Actif' : 'Inactif';
  }

  String _formatLastSync() {
    if (dataSource.lastSync == null) return 'Jamais';
    
    final now = DateTime.now();
    final difference = now.difference(dataSource.lastSync!);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}