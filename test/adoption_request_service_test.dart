import 'dart:math';

import 'package:adopals/adoption_request_service.dart';
import 'package:adopals/models/pet_model.dart';
import 'package:flutter_test/flutter_test.dart';

PetModel _pet({AdoptionFeeBreakdown? fee, double price = 0}) => PetModel(
      id: 'pet-1',
      name: 'Bruno',
      price: price,
      quantity: 1,
      availabilityStatus: 'Available',
      category: 'Dog',
      breed: 'Indie',
      photos: const ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      createdBy: 'giver-1',
      adoptionFee: fee,
    );

Map<String, dynamic> _order(String status, List<String> petIds) => {
      'status': status,
      'orderItems': [
        {
          'sellerId': 'giver-1',
          'pets': [for (final id in petIds) {'petId': id}],
        },
      ],
    };

void main() {
  group('buildAdoptionOrderPayload', () {
    final payload = buildAdoptionOrderPayload(
      pet: _pet(price: 1500),
      giverId: 'giver-1',
      giverName: 'Asha',
      applicantId: 'user-1',
      applicantName: 'Ravi',
      applicantEmail: 'ravi@example.com',
      message: '  Hello there  ',
      orderId: 'ADOPTION-1-ABCDEFGHI',
      createdAt: 'TS',
    );

    test('sets createdBy to the adopter (Firestore rules) and sellerIds to the giver', () {
      expect(payload['createdBy'], 'user-1');
      expect(payload['sellerIds'], ['giver-1']);
      expect(payload['createdAt'], 'TS');
      expect(payload['orderId'], 'ADOPTION-1-ABCDEFGHI');
    });

    test('matches the web OrderModel shape with no payment', () {
      expect(payload['status'], 'Application Received');
      expect(payload['paymentMethod'], 'pay-on-adoption');
      expect(payload['paymentDetails'], isNull);
      expect(payload['totalAmount'], 1500);
      final item = (payload['orderItems'] as List).single as Map;
      expect(item['sellerId'], 'giver-1');
      expect(item['sellerName'], 'Asha');
      final pet = (item['pets'] as List).single as Map;
      expect(pet['petId'], 'pet-1');
      expect(pet['petName'], 'Bruno');
      expect(pet['thumbnailUrl'], 'https://example.com/a.jpg');
      expect(pet['category'], 'Dog');
      expect(pet['breed'], 'Indie');
      expect(pet['status'], 'Application Received');
      expect(pet['adoptedAt'], isNull);
    });

    test('carries the trimmed message and applicant contact', () {
      expect(payload['message'], 'Hello there');
      expect(payload['applicantName'], 'Ravi');
      expect(payload['applicantEmail'], 'ravi@example.com');
    });

    test('uses the adoption fee total when the pet has one', () {
      final p = buildAdoptionOrderPayload(
        pet: _pet(price: 10, fee: AdoptionFeeBreakdown(careRecoveryFee: 500, totalFee: 800, isFree: false)),
        giverId: 'g',
        giverName: 'G',
        applicantId: 'u',
        applicantName: null,
        applicantEmail: null,
        message: 'hi',
        orderId: 'o',
        createdAt: 'TS',
      );
      expect(p['totalAmount'], 800);
      expect(p['applicantName'], '');
      expect(p['applicantEmail'], '');
    });
  });

  test('buildAdoptionRequestDetail matches the web AdoptionRequest fields', () {
    final d = buildAdoptionRequestDetail(
      pet: _pet(),
      giverId: 'giver-1',
      giverName: 'Asha',
      applicantId: 'user-1',
      applicantName: 'Ravi',
      applicantEmail: 'ravi@example.com',
      message: 'Hi!',
      parentDocId: 'order-doc',
      timestamp: 'TS',
    );
    expect(d['petId'], 'pet-1');
    expect(d['petGiverId'], 'giver-1');
    expect(d['petGiverName'], 'Asha');
    expect(d['applicantId'], 'user-1');
    expect(d['email'], 'ravi@example.com');
    expect(d['additionalNotes'], 'Hi!');
    expect(d['status'], 'Pending');
    expect(d['submittedAt'], 'TS');
    expect(d['orderId'], 'order-doc');
  });

  group('normalizeAdoptionMessage', () {
    test('caps at 500 characters', () {
      expect(normalizeAdoptionMessage('a' * 700).length, adoptionMessageMaxLength);
    });
    test('default message names the pet and fits the limit', () {
      final m = defaultAdoptionMessage('Bruno');
      expect(m, contains('Bruno'));
      expect(m.length, lessThanOrEqualTo(adoptionMessageMaxLength));
      expect(defaultAdoptionMessage(null), contains('this pet'));
    });
  });

  test('generateAdoptionOrderId uses the web format', () {
    final id = generateAdoptionOrderId(now: DateTime.fromMillisecondsSinceEpoch(1700000000000), random: Random(1));
    expect(id, matches(RegExp(r'^ADOPTION-1700000000000-[A-Z0-9]{9}$')));
  });

  group('hasOpenRequestForPet (duplicate check)', () {
    test('true for an open request containing the pet', () {
      expect(hasOpenRequestForPet([_order('Application Received', ['pet-1'])], 'pet-1'), isTrue);
      expect(hasOpenRequestForPet([_order('Application Under Review', ['x', 'pet-1'])], 'pet-1'), isTrue);
      expect(hasOpenRequestForPet([_order('Application Approved', ['pet-1'])], 'pet-1'), isTrue);
    });

    test('false for closed requests, other pets or no requests', () {
      expect(hasOpenRequestForPet([], 'pet-1'), isFalse);
      expect(hasOpenRequestForPet([_order('Adoption Cancelled', ['pet-1'])], 'pet-1'), isFalse);
      expect(hasOpenRequestForPet([_order('Application Rejected', ['pet-1'])], 'pet-1'), isFalse);
      expect(hasOpenRequestForPet([_order('Application Received', ['pet-2'])], 'pet-1'), isFalse);
    });

    test('ignores malformed documents', () {
      expect(
        hasOpenRequestForPet([
          {'status': 'Application Received'},
          {'status': 'Application Received', 'orderItems': 'bad'},
          {'status': 'Application Received', 'orderItems': [{'pets': null}]},
        ], 'pet-1'),
        isFalse,
      );
    });
  });
}
