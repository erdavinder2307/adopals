import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'models/pet_model.dart';

/// v1 adoption flow: the adopter sends a request + short message to the pet giver.
/// No cart, no payment in the app.
///
/// Writes the same shape as the web app (adopals-app AdoptionService.submitAdoptionOrder):
/// one `adoptionOrders/{id}` document (what the giver's "Adoption Requests" page and the
/// adopter's "My Adoptions" page read, via `sellerIds` / `createdBy`) plus one
/// `adoptionOrders/{id}/adoptionRequests/{reqId}` detail document.

const String adoptionOrdersCollection = 'adoptionOrders';
const String adoptionRequestsSubcollection = 'adoptionRequests';

/// Status the web app sets on a new request (order level and pet level).
const String initialAdoptionStatus = 'Application Received';

/// Order statuses the web app treats as an open (active) request for a pet
/// (AdoptionService.hasUserSubmittedRequestForPet).
const List<String> openAdoptionStatuses = [
  'Application Received',
  'Application Under Review',
  'Application Approved',
];

const int adoptionMessageMaxLength = 500;

/// Friendly text pre-filled in the message field.
String defaultAdoptionMessage(String? petName) {
  final name = (petName == null || petName.trim().isEmpty) ? 'this pet' : petName.trim();
  return "Hi! I'd love to adopt $name. Could you tell me the next steps? Thank you!";
}

/// Same format as the web OrderBuilder.generateOrderId(): ADOPTION-<ms>-<9 upper-case chars>.
String generateAdoptionOrderId({DateTime? now, Random? random}) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rnd = random ?? Random.secure();
  final suffix = List.generate(9, (_) => chars[rnd.nextInt(chars.length)]).join();
  return 'ADOPTION-${(now ?? DateTime.now()).millisecondsSinceEpoch}-$suffix';
}

/// Trims the message and caps it at [adoptionMessageMaxLength] characters.
String normalizeAdoptionMessage(String message) {
  final trimmed = message.trim();
  return trimmed.length > adoptionMessageMaxLength
      ? trimmed.substring(0, adoptionMessageMaxLength)
      : trimmed;
}

double _feeFor(PetModel pet) => pet.adoptionFee?.totalFee ?? pet.price;

/// Builds the `adoptionOrders/{id}` document (web OrderModel shape).
/// [createdAt] is `FieldValue.serverTimestamp()` in the app; tests pass a fixed value.
Map<String, dynamic> buildAdoptionOrderPayload({
  required PetModel pet,
  required String giverId,
  required String giverName,
  required String applicantId,
  required String? applicantName,
  required String? applicantEmail,
  required String message,
  required String orderId,
  required Object createdAt,
}) {
  final fee = _feeFor(pet);
  return {
    'orderId': orderId,
    'orderItems': [
      {
        'sellerName': giverName,
        'sellerId': giverId,
        'pets': [
          {
            'petId': pet.id,
            'petName': pet.name ?? '',
            'price': fee,
            'thumbnailUrl': (pet.photos != null && pet.photos!.isNotEmpty) ? pet.photos!.first : '',
            'category': pet.category ?? '',
            'breed': pet.breed ?? '',
            'status': initialAdoptionStatus,
            'adoptedAt': null,
          },
        ],
      },
    ],
    'sellerIds': [giverId],
    'paymentMethod': 'pay-on-adoption',
    'paymentDetails': null,
    'address': null,
    'totalAmount': fee,
    'status': initialAdoptionStatus,
    'createdAt': createdAt,
    'createdBy': applicantId,
    'applicantName': applicantName ?? '',
    'applicantEmail': applicantEmail ?? '',
    'applicantPhone': '',
    'message': normalizeAdoptionMessage(message),
    'source': 'mobile-app',
  };
}

/// Builds the `adoptionOrders/{id}/adoptionRequests/{reqId}` detail document
/// (web AdoptionRequest interface). Fields the v1 mobile flow does not collect are left empty.
Map<String, dynamic> buildAdoptionRequestDetail({
  required PetModel pet,
  required String giverId,
  required String giverName,
  required String applicantId,
  required String? applicantName,
  required String? applicantEmail,
  required String message,
  required String parentDocId,
  required Object timestamp,
}) {
  final text = normalizeAdoptionMessage(message);
  return {
    'petId': pet.id,
    'petName': pet.name ?? '',
    'petGiverId': giverId,
    'petGiverName': giverName,
    'applicantId': applicantId,
    'applicantName': applicantName ?? '',
    'email': applicantEmail ?? '',
    'phone': '',
    'address': '',
    'homeType': '',
    'hasOtherPets': false,
    'hasChildren': false,
    'experienceWithPets': '',
    'adoptionReason': text,
    'workSchedule': '',
    'additionalNotes': text,
    'agreesToTerms': false,
    'status': 'Pending',
    'submittedAt': timestamp,
    'lastUpdatedAt': timestamp,
    'orderId': parentDocId,
  };
}

/// True when one of the adopter's `adoptionOrders` documents is still open and
/// contains [petId] (same check as the web hasUserSubmittedRequestForPet).
bool hasOpenRequestForPet(Iterable<Map<String, dynamic>> orders, String petId) {
  for (final order in orders) {
    if (!openAdoptionStatuses.contains(order['status'])) continue;
    final items = order['orderItems'];
    if (items is! List) continue;
    for (final item in items) {
      final pets = item is Map ? item['pets'] : null;
      if (pets is! List) continue;
      for (final p in pets) {
        if (p is Map && p['petId'] == petId) return true;
      }
    }
  }
  return false;
}

class AdoptionRequestService {
  AdoptionRequestService({FirebaseFirestore? firestore}) : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _db => _firestoreOverride ?? FirebaseFirestore.instance;

  /// Single-field query (no composite index needed); status filtered on the client.
  Future<bool> hasOpenRequest({required String applicantId, required String petId}) async {
    final snap = await _db
        .collection(adoptionOrdersCollection)
        .where('createdBy', isEqualTo: applicantId)
        .get();
    return hasOpenRequestForPet(snap.docs.map((d) => d.data()), petId);
  }

  /// Writes the order document, then its request detail. Returns the order document id.
  ///
  /// Not a batch: the Firestore rules check the parent order with get(), which in a batch still sees
  /// the order as missing. Like the website, a failed detail write still counts as sent, because the
  /// giver finds the order through sellerIds.
  Future<String> submitRequest({
    required PetModel pet,
    required String giverId,
    required String giverName,
    required String applicantId,
    required String? applicantName,
    required String? applicantEmail,
    required String message,
  }) async {
    final orderRef = _db.collection(adoptionOrdersCollection).doc();
    final requestRef = orderRef.collection(adoptionRequestsSubcollection).doc();
    final now = FieldValue.serverTimestamp();
    await orderRef.set(
      buildAdoptionOrderPayload(
        pet: pet,
        giverId: giverId,
        giverName: giverName,
        applicantId: applicantId,
        applicantName: applicantName,
        applicantEmail: applicantEmail,
        message: message,
        orderId: generateAdoptionOrderId(),
        createdAt: now,
      ),
    );
    try {
      await requestRef.set(
        buildAdoptionRequestDetail(
          pet: pet,
          giverId: giverId,
          giverName: giverName,
          applicantId: applicantId,
          applicantName: applicantName,
          applicantEmail: applicantEmail,
          message: message,
          parentDocId: orderRef.id,
          timestamp: now,
        ),
      );
    } catch (e) {
      debugPrint('Adoption request detail not written: $e');
    }
    return orderRef.id;
  }
}
