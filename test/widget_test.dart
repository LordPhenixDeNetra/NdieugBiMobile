// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ndieug_bi_mobile/main.dart';
import 'package:ndieug_bi_mobile/data/repositories/invoice_repository.dart';
import 'package:ndieug_bi_mobile/services/database_service.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Create a mock database service and invoice repository for testing
    final databaseService = DatabaseService();
    final invoiceRepository = InvoiceRepository(databaseService);
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(NdieugBiApp(invoiceRepository: invoiceRepository));

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
