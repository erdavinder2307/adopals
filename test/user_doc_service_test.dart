import 'package:flutter_test/flutter_test.dart';

import 'package:adopals/user_doc_service.dart';

void main() {
  group('missingUserFields', () {
    test('new user gets all basic fields and the buyer role', () {
      expect(
        missingUserFields(null, uid: 'u1', email: 'a@b.com', name: 'Ann'),
        {
          'uid': 'u1',
          'id': 'u1',
          'userId': 'u1',
          'email': 'a@b.com',
          'name': 'Ann',
          'username': 'Ann',
          'roles': ['buyer'],
          'role': 'buyer',
        },
      );
    });

    test('existing fields are never overwritten', () {
      expect(
        missingUserFields({
          'uid': 'u1',
          'id': 'u1',
          'userId': 'u1',
          'name': 'Old Name',
          'username': 'old',
          'email': null,
          'roles': ['buyer', 'seller'],
          'role': 'seller',
        }, uid: 'u1', email: 'a@b.com', name: 'New Name'),
        {'email': 'a@b.com'},
      );
    });

    test('older account without roles gets the buyer role', () {
      expect(
        missingUserFields({
          'uid': 'u1',
          'id': 'u1',
          'userId': 'u1',
          'email': 'a@b.com',
          'name': 'Ann',
          'username': 'Ann',
        }, uid: 'u1', email: 'a@b.com', name: 'Ann'),
        {'roles': ['buyer'], 'role': 'buyer'},
      );
    });

    test('empty or null values are skipped', () {
      expect(
        missingUserFields({}, uid: 'u1', email: null, name: ''),
        {'uid': 'u1', 'id': 'u1', 'userId': 'u1', 'roles': ['buyer'], 'role': 'buyer'},
      );
    });

    test('never adds the admin role', () {
      final fields = missingUserFields(null, uid: 'u1', email: 'a@b.com', name: 'Ann');
      expect(fields['roles'], isNot(contains('admin')));
      expect(fields['role'], isNot('admin'));
    });
  });
}
