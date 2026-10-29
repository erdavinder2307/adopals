import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Returns the basic profile fields that are missing (absent or null) in
/// [existing]. Fields already present are never included, so an existing
/// user's data is not overwritten. Mirrors the web app's createUser: every
/// account starts as a buyer, which the Firestore rules need to place orders.
Map<String, dynamic> missingUserFields(
  Map<String, dynamic>? existing, {
  required String uid,
  String? email,
  String? name,
}) {
  final candidates = <String, dynamic>{
    'uid': uid,
    'id': uid,
    'userId': uid,
    'email': email,
    'name': name,
    'username': name,
    'roles': ['buyer'],
    'role': 'buyer',
  };
  final missing = <String, dynamic>{};
  candidates.forEach((key, value) {
    final empty = value == null || (value is String && value.isEmpty);
    if (!empty && existing?[key] == null) missing[key] = value;
  });
  return missing;
}

/// Makes sure users/{uid} exists after a sign-in or sign-up. Creates it for new
/// users and only fills in missing fields for existing ones.
Future<void> ensureUserDoc(User user, {String? name}) async {
  try {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await ref.get().timeout(const Duration(seconds: 5));
    final fields = missingUserFields(
      snapshot.data(),
      uid: user.uid,
      email: user.email,
      name: name ?? user.displayName,
    );
    if (!snapshot.exists) {
      fields['createdAt'] = FieldValue.serverTimestamp();
    }
    if (fields.isEmpty) return;
    await ref
        .set(fields, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    // Do not block sign-in if the profile doc cannot be written.
    debugPrint('ensureUserDoc failed: $e');
  }
}
