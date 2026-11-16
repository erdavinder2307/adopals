import 'package:adopals/models/pet_location.dart';
import 'package:adopals/models/pet_model.dart';
import 'package:flutter_test/flutter_test.dart';

const _full = '12 MG Road, Indiranagar, Bengaluru, Karnataka 560038, India';

PetModel _pet({String? location = _full, String? createdBy = 'giver-uid'}) =>
    PetModel(id: 'p1', price: 0, quantity: 1, availabilityStatus: '', location: location, createdBy: createdBy);

void main() {
  group('publicPetLocation', () {
    const cases = {
      '12 MG Road, Indiranagar, Bengaluru, Karnataka 560038, India': 'Bengaluru, India',
      'Sector 70, Mohali, Punjab, India': 'Mohali, India',
      '45, Green Avenue, Mohali, India': 'Mohali, India',
      'Sector 17, Chandigarh, India': 'Chandigarh, India',
      'Baker Street, Marylebone, London, UK': 'London, UK',
      '#12, Green Avenue, Mohali': 'Mohali',
      'Model Town, Ludhiana, Punjab': 'Ludhiana',
      'MOHALI, PUNJAB, INDIA': 'MOHALI, INDIA',
      'Mohali': 'Mohali',
      'Bengaluru, India': 'Bengaluru, India',
    };
    cases.forEach((address, city) {
      test('$address -> $city', () => expect(publicPetLocation(address), city));
    });

    test('gives nothing, never the street, when the address has no city part', () {
      expect(publicPetLocation('221B'), '');
      expect(publicPetLocation('12 MG Road'), '');
      expect(publicPetLocation(''), '');
      expect(publicPetLocation(null), '');
      expect(publicPetLocation(42), '');
    });

    test('is idempotent', () {
      for (final address in [_full, 'Sector 70, Mohali, Punjab, India', 'Green Avenue, Mohali']) {
        final city = publicPetLocation(address);
        expect(publicPetLocation(city), city);
      }
    });
  });

  group('PetModel.locationFor', () {
    test('the pet giver sees the full address', () {
      expect(_pet().locationFor(viewerId: 'giver-uid'), _full);
    });

    test('an admin sees the full address', () {
      expect(_pet().locationFor(viewerId: 'admin-uid', isAdmin: true), _full);
    });

    test('another user sees the city only', () {
      expect(_pet().locationFor(viewerId: 'other-uid'), 'Bengaluru, India');
    });

    test('a signed-out visitor, or an unknown viewer, sees the city only', () {
      expect(_pet().locationFor(), 'Bengaluru, India');
      expect(_pet().locationFor(viewerId: ''), 'Bengaluru, India');
      expect(_pet(createdBy: null).locationFor(viewerId: ''), 'Bengaluru, India');
      expect(_pet(createdBy: '').locationFor(viewerId: ''), 'Bengaluru, India');
    });

    test('shows nothing when there is no location', () {
      expect(_pet(location: null).locationFor(viewerId: 'giver-uid'), '');
      expect(_pet(location: '  ').locationFor(viewerId: 'giver-uid'), '');
      expect(_pet(location: null).locationFor(viewerId: 'other-uid'), '');
    });

    test('shows nothing, not the street, when another user\'s address has no city', () {
      expect(_pet(location: '221B').locationFor(viewerId: 'other-uid'), '');
      expect(_pet(location: '12 MG Road').locationFor(viewerId: 'other-uid'), '');
    });
  });

  group('PetModel.fromMap', () {
    Map<String, dynamic> data() => {'name': 'Bruno', 'location': _full, 'createdBy': 'giver-uid'};

    test('keeps the full address for the pet giver', () {
      expect(PetModel.fromMap(data(), 'p1', viewerId: 'giver-uid').location, _full);
    });

    test('keeps the full address for an admin', () {
      expect(PetModel.fromMap(data(), 'p1', viewerId: 'admin-uid', isAdmin: true).location, _full);
    });

    test('keeps the city only for other users and signed-out visitors', () {
      expect(PetModel.fromMap(data(), 'p1', viewerId: 'other-uid').location, 'Bengaluru, India');
      expect(PetModel.fromMap(data(), 'p1').location, 'Bengaluru, India');
    });

    test('leaves a missing location empty', () {
      expect(PetModel.fromMap({'name': 'Bruno'}, 'p1', viewerId: 'other-uid').location, isNull);
    });
  });

  group('PetModel.fromPublicPet', () {
    test('keeps the city only, even when the public copy holds more of the address', () {
      final pet = PetModel.fromPublicPet({'name': 'Bruno', 'location': 'Indiranagar, Bengaluru, India'}, 'p1');
      expect(pet.location, 'Bengaluru, India');
      expect(pet.locationFor(), 'Bengaluru, India');
    });

    test('shows nothing when the address has no city', () {
      expect(PetModel.fromPublicPet({'name': 'Bruno', 'location': '221B'}, 'p1').location, '');
      expect(PetModel.fromPublicPet({'name': 'Bruno'}, 'p1').location, isNull);
    });
  });
}
