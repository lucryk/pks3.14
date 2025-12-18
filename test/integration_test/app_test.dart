import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter5/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end tests', () {
    testWidgets('Complete note flow', (WidgetTester tester) async {
      
      app.main();
      await tester.pumpAndSettle();
      
      expect(find.text('Первая заметка'), findsOneWidget);
      
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byType(TextField).first,
        'Тестовая заметка'
      );
      await tester.enterText(
        find.byType(TextField).last,
        'Содержание тестовой заметки'
      );
      
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();
      
      expect(find.text('Тестовая заметка'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      
      expect(find.text('Тестовая заметка'), findsNothing);
    });
  });
}