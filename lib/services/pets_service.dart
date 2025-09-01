import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet_model.dart';

class PetsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get featured pets
  Stream<List<PetModel>> getFeaturedPets({int limit = 6}) {
    return _firestore
        .collection('pets')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get all pets with optional filters
  Stream<List<PetModel>> getAllPets({
    String? category,
    String? breed,
    String? gender,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    int limit = 20,
  }) {
    Query query = _firestore.collection('pets');

    // Apply filters
    if (category != null && category.isNotEmpty) {
      query = query.where('category.name', isEqualTo: category);
    }
    if (breed != null && breed.isNotEmpty) {
      query = query.where('breed.name', isEqualTo: breed);
    }
    if (gender != null && gender.isNotEmpty) {
      query = query.where('gender', isEqualTo: gender);
    }
    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      List<PetModel> pets = snapshot.docs
          .map((doc) => PetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        pets = pets.where((pet) {
          final nameMatch = pet.name.toLowerCase().contains(searchQuery.toLowerCase());
          final breedMatch = pet.getBreedName().toLowerCase().contains(searchQuery.toLowerCase());
          final categoryMatch = pet.getCategoryName().toLowerCase().contains(searchQuery.toLowerCase());
          return nameMatch || breedMatch || categoryMatch;
        }).toList();
      }

      return pets;
    });
  }

  // Get pets with fallback (for featured section)
  Future<List<PetModel>> getPetsWithFallback({int limit = 3}) async {
    try {
      // First try to get featured pets
      final featuredQuery = await _firestore
          .collection('pets')
          .where('isFeatured', isEqualTo: true)
          .limit(limit)
          .get();

      if (featuredQuery.docs.isNotEmpty) {
        return featuredQuery.docs
            .map((doc) => PetModel.fromMap(doc.data(), doc.id))
            .toList();
      }

      // Fallback to random pets with photos
      final allPetsQuery = await _firestore
          .collection('pets')
          .limit(20) // Get more to shuffle
          .get();

      List<PetModel> allPets = allPetsQuery.docs
          .map((doc) => PetModel.fromMap(doc.data(), doc.id))
          .where((pet) => pet.photos != null && pet.photos!.isNotEmpty) // Filter pets with photos
          .toList();

      // Shuffle and return limited number
      allPets.shuffle(Random());
      return allPets.take(limit).toList();
    } catch (e) {
      print('Error fetching pets: $e');
      return [];
    }
  }

  // Get pet by ID
  Future<PetModel?> getPetById(String petId) async {
    try {
      final doc = await _firestore.collection('pets').doc(petId).get();
      if (doc.exists) {
        return PetModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching pet: $e');
      return null;
    }
  }

  // Add pet to favorites
  Future<bool> addToFavorites(String petId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(petId)
          .set({
        'petId': petId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Remove pet from favorites
  Future<bool> removeFromFavorites(String petId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(petId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Get user's favorite pet IDs
  Stream<List<String>> getFavoritePetIds() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Share pet (for analytics/logging purposes)
  Future<void> sharePet(String petId) async {
    // This would typically integrate with native sharing
    // For now, just log the action
    print('Sharing pet: $petId');
    
    // You could add analytics logging here similar to the Angular app
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('analytics').add({
          'action': 'pet_share',
          'petId': petId,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'platform': 'flutter',
        });
      }
    } catch (e) {
      print('Error logging share action: $e');
    }
  }

  // Log pet view for analytics
  Future<void> logPetView(String petId, String petName, String category) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('analytics').add({
        'action': 'pet_view',
        'petId': petId,
        'petName': petName,
        'category': category,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
    } catch (e) {
      print('Error logging pet view: $e');
    }
  }

  // Get categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Get breeds
  Future<List<Map<String, dynamic>>> getBreeds() async {
    try {
      final snapshot = await _firestore.collection('breeds').get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error fetching breeds: $e');
      return [];
    }
  }
}
