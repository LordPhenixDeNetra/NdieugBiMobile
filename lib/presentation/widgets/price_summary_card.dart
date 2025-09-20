import 'package:flutter/material.dart';

class PriceSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;

  const PriceSummaryCard({
    Key? key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des prix',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(
              context,
              'Sous-total',
              subtotal,
              theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            if (discount > 0)
              _buildPriceRow(
                context,
                'Remise',
                -discount,
                theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            if (discount > 0) const SizedBox(height: 8),
            if (tax > 0)
              _buildPriceRow(
                context,
                'Taxe',
                tax,
                theme.textTheme.bodyLarge,
              ),
            if (tax > 0) const SizedBox(height: 8),
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              'Total',
              total,
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double amount,
    TextStyle? style, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style,
        ),
        Container(
          padding: isTotal 
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : EdgeInsets.zero,
          decoration: isTotal
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: style,
          ),
        ),
      ],
    );
  }
}