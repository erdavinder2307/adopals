import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> reportReasons = [
  'Inappropriate or offensive',
  'Scam or misleading',
  'Animal welfare concern',
  'Other',
];

/// Fields of a listing report, without the server timestamp.
Map<String, dynamic> buildPetReport({
  required String petId,
  required String? sellerId,
  required String reason,
  required String details,
  required String reporterId,
}) {
  return {
    'type': 'pet',
    'petId': petId,
    'sellerId': sellerId,
    'reason': reason,
    'details': details.trim(),
    'reporterId': reporterId,
    'status': 'open',
  };
}

Future<void> submitPetReport(Map<String, dynamic> report) {
  return FirebaseFirestore.instance.collection('reports').add({
    ...report,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
