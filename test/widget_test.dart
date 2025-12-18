import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter5/main.dart';

void main() {
  testWidgets('App renders with correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    expect(find.text('Мои заметки'), findsOneWidget);
  });

  testWidgets('Initial notes are displayed', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    
    await tester.pumpAndSettle();
    
    expect(find.text('Первая заметка'), findsOneWidget);
    expect(find.text('Список покупок'), findsOneWidget);
    expect(find.text('Идеи для проекта'), findsOneWidget);
  });

  testWidgets('FAB is present', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('NoteEditScreen renders correctly for new note', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NoteEditScreen(),
      ),
    );
    
    expect(find.text('Новая заметка'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('NoteEditScreen renders correctly for existing note', (WidgetTester tester) async {
    final note = Note.create(
      title: 'Test Note',
      content: 'Test Content',
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: NoteEditScreen(existingNote: note),
      ),
    );
    
    expect(find.text('Редактировать заметку'), findsOneWidget);
  });
}