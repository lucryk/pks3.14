import 'package:flutter_test/flutter_test.dart';
import 'package:flutter5/main.dart';

void main() {
  test('Note.create generates ID', () {
    final note = Note.create(title: 'Test', content: 'Content');
    expect(note.id, isNotNull);
    expect(note.title, 'Test');
    expect(note.content, 'Content');
  });

  test('Note.copyWith updates title', () {
    final original = Note.create(title: 'Original', content: 'Content');
    final updated = original.copyWith(title: 'Updated');
    expect(updated.title, 'Updated');
    expect(updated.content, 'Content');
  });
}