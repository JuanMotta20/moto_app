// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:moto_app/app.dart';
import 'package:moto_app/providers/auth_provider.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build the app wrapped with the required provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MotoApp(),
      ),
    );

    // Allow widget tree to settle
    await tester.pumpAndSettle();

    // Verify welcome text and navigation buttons are present
    expect(find.text('MotoTaxi App'), findsOneWidget);
    expect(find.text('Tu transporte rápido y seguro'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
