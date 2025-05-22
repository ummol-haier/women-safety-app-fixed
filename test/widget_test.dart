import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ally/main.dart';

void main() {
  testWidgets('App loads and shows initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Since the initial screen is loaded asynchronously, wait for it
    await tester.pumpAndSettle();

    // Verify that the RoleSelectionScreen or UserHomeScreen or GuardianHomeScreen is shown
    expect(find.byType(Scaffold), findsWidgets);
  });
}
