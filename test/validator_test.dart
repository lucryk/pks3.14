import 'package:flutter_test/flutter_test.dart';

class NoteValidator {
  static String? validateTitle(String? title) {
    if (title == null || title.isEmpty) {
      return 'Title cannot be empty';
    }
    return null;
  }
}

void main() {
  test('Empty title returns error', () {
    expect(NoteValidator.validateTitle(''), 'Title cannot be empty');
  });

  test('Valid title returns null', () {
    expect(NoteValidator.validateTitle('Valid Title'), null);
  });
}