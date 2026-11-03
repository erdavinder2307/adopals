import 'package:adopals/block_service.dart';
import 'package:adopals/models/pet_model.dart';
import 'package:adopals/report_service.dart';
import 'package:flutter_test/flutter_test.dart';

PetModel _pet(String id, String? createdBy) =>
    PetModel(id: id, price: 0, quantity: 1, availabilityStatus: '', createdBy: createdBy);

void main() {
  group('filterBlockedPets', () {
    final pets = [_pet('p1', 'giverA'), _pet('p2', 'giverB'), _pet('p3', null), _pet('p4', '')];

    test('returns all pets when nothing is blocked', () {
      expect(filterBlockedPets(pets, {}).map((p) => p.id), ['p1', 'p2', 'p3', 'p4']);
    });

    test('hides pets of blocked givers and keeps pets with no giver', () {
      expect(filterBlockedPets(pets, {'giverA'}).map((p) => p.id), ['p2', 'p3', 'p4']);
    });
  });

  group('blockedIdsFromUserData', () {
    test('reads a list of ids', () {
      expect(blockedIdsFromUserData({'blockedUsers': ['a', 'b', '']}), {'a', 'b'});
    });

    test('handles a missing doc or field', () {
      expect(blockedIdsFromUserData(null), isEmpty);
      expect(blockedIdsFromUserData({'name': 'x'}), isEmpty);
      expect(blockedIdsFromUserData({'blockedUsers': 'not-a-list'}), isEmpty);
    });
  });

  test('buildPetReport fills the report fields', () {
    final report = buildPetReport(
      petId: 'p1',
      sellerId: 'giverA',
      reason: reportReasons.first,
      details: '  looks fake  ',
      reporterId: 'me',
    );
    expect(report, {
      'type': 'pet',
      'petId': 'p1',
      'sellerId': 'giverA',
      'reason': 'Inappropriate or offensive',
      'details': 'looks fake',
      'reporterId': 'me',
      'status': 'open',
    });
  });
}
