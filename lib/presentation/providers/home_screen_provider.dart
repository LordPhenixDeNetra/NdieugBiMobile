import 'package:flutter/material.dart';

class HomeScreenProvider extends ChangeNotifier {
  // Navigation methods
  void navigateToSales(BuildContext context) {
    // TODO: Navigate to sales screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les ventes')),
    );
  }

  void navigateToInventory(BuildContext context) {
    // TODO: Navigate to inventory screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers l\'inventaire')),
    );
  }

  void navigateToInvoices(BuildContext context) {
    // TODO: Navigate to invoices screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les factures')),
    );
  }

  void navigateToReports(BuildContext context) {
    // TODO: Navigate to reports screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers les rapports')),
    );
  }

  void navigateToActivity(BuildContext context) {
    // TODO: Navigate to activity screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigation vers l\'activité')),
    );
  }
}