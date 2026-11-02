import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../integration_test/ait_values.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('ait_values_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String content) =>
      File('${dir.path}/ait-sign-in.json')..writeAsStringSync(content);

  test('reads the three values and deletes the file', () {
    final file = write(
        '{"AIT_EMAIL":"a@example.com","AIT_PASSWORD":"pw","AIT_EXPECTED_EMAIL":"A@example.com"}');
    final values = takeAitValues(file.path);
    expect(values, isNotNull);
    expect(values!.email, 'a@example.com');
    expect(values.password, 'pw');
    expect(values.expectedEmail, 'A@example.com');
    expect(file.existsSync(), isFalse);
  });

  test('returns null for an empty path or a missing file', () {
    expect(takeAitValues(''), isNull);
    expect(takeAitValues('${dir.path}/missing.json'), isNull);
  });

  test('deletes the file also when it is not valid', () {
    for (final content in [
      'not json',
      '[]',
      '{"AIT_EMAIL":"a@example.com","AIT_PASSWORD":"pw"}',
      '{"AIT_EMAIL":"a@example.com","AIT_PASSWORD":"","AIT_EXPECTED_EMAIL":"a@example.com"}',
      '{"AIT_EMAIL":1,"AIT_PASSWORD":"pw","AIT_EXPECTED_EMAIL":"a@example.com"}',
    ]) {
      final file = write(content);
      expect(takeAitValues(file.path), isNull, reason: content);
      expect(file.existsSync(), isFalse, reason: content);
    }
  });

  test('returns null and deletes a file that is not valid UTF-8', () {
    final file = File('${dir.path}/ait-sign-in.json')
      ..writeAsBytesSync([0x7b, 0xff, 0xfe, 0x7d]);
    expect(takeAitValues(file.path), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('sameEmail ignores case and spaces, and a missing email never matches',
      () {
    expect(sameEmail(' A@Example.com ', 'a@example.com'), isTrue);
    expect(sameEmail('b@example.com', 'a@example.com'), isFalse);
    expect(sameEmail(null, 'a@example.com'), isFalse);
  });
}
