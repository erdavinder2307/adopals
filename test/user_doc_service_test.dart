import 'package:flutter_test/flutter_test.dart';

import 'package:adopals/user_doc_service.dart';

void main() {
  group('missingUserFields', () {
    test('new user gets all basic fields', () {
      expect(
        missingUserFields(null, uid: 'u1', email: 'a@b.com', name: 'Ann'),
        {'uid': 'u1', 'email': 'a@b.com', 'name': 'Ann'},
      );
    });

    test('existing fields are never overwritten', () {
      expect(
        missingUserFields({'uid': 'u1', 'name': 'Old Name', 'email': null},
            uid: 'u1', email: 'a@b.com', name: 'New Name'),
        {'email': 'a@b.com'},
      );
    });

    test('empty or null values are skipped', () {
      expect(missingUserFields({}, uid: 'u1', email: null, name: ''), {'uid': 'u1'});
    });
  });
}
