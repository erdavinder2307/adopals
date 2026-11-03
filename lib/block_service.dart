import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'models/pet_model.dart';

/// The id of the pet giver who listed [pet], or null when unknown.
String? petGiverId(PetModel pet) {
  final id = pet.createdBy;
  return (id == null || id.isEmpty) ? null : id;
}

/// Returns [pets] without the listings of any giver in [blockedIds].
List<PetModel> filterBlockedPets(List<PetModel> pets, Set<String> blockedIds) {
  if (blockedIds.isEmpty) return pets;
  return pets.where((pet) {
    final giverId = petGiverId(pet);
    return giverId == null || !blockedIds.contains(giverId);
  }).toList();
}

/// Reads a `blockedUsers` field from a users/{uid} document.
Set<String> blockedIdsFromUserData(Map<String, dynamic>? data) {
  final raw = data?['blockedUsers'];
  if (raw is! List) return <String>{};
  return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
}

/// Givers the signed-in user has blocked, kept in users/{uid}.blockedUsers.
class BlockService extends ChangeNotifier {
  BlockService._();
  static final BlockService instance = BlockService._();

  Set<String> _blockedIds = <String>{};
  String? _loadedForUid;

  Set<String> get blockedIds => Set.unmodifiable(_blockedIds);

  bool isBlocked(String? userId) => userId != null && _blockedIds.contains(userId);

  /// Loads the blocked list for the current user. Errors leave the list empty.
  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _set(<String>{}, null);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _set(blockedIdsFromUserData(doc.data()), uid);
    } catch (e) {
      debugPrint('Could not load blocked users: $e');
      if (_loadedForUid != uid) _set(<String>{}, uid);
    }
  }

  /// Blocks [giverId] for the current user. Throws if the write fails.
  Future<void> block(String giverId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {'blockedUsers': FieldValue.arrayUnion([giverId])},
      SetOptions(merge: true),
    );
    _set({..._blockedIds, giverId}, uid);
  }

  void _set(Set<String> ids, String? uid) {
    _blockedIds = ids;
    _loadedForUid = uid;
    notifyListeners();
  }
}
