import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String? id;
  final String name;
  final String? breed;
  final String? category;
  final String? description;
  final String? location;
  final String? gender;
  final double? price;
  final List<String>? photos;
  final List<String>? thumbnails;
  final bool isFavorite;
  final String? age;
  final String? sellerId;
  final DateTime? createdAt;
  final bool? isFeatured;
  final Map<String, dynamic>? breedInfo;
  final Map<String, dynamic>? categoryInfo;

  PetModel({
    this.id,
    required this.name,
    this.breed,
    this.category,
    this.description,
    this.location,
    this.gender,
    this.price,
    this.photos,
    this.thumbnails,
    this.isFavorite = false,
    this.age,
    this.sellerId,
    this.createdAt,
    this.isFeatured,
    this.breedInfo,
    this.categoryInfo,
  });

  factory PetModel.fromMap(Map<String, dynamic> data, String id, {List<String>? favoritePetIds}) {
    return PetModel(
      id: id,
      name: data['name'] ?? '',
      breed: data['breed'] is Map ? data['breed']['name'] : data['breed']?.toString(),
      category: data['category'] is Map ? data['category']['name'] : data['category']?.toString(),
      description: data['description'],
      location: data['location'],
      gender: data['gender'],
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] is double)
              ? data['price'] as double
              : (data['price'] is String)
                  ? double.tryParse(data['price'])
                  : null,
      photos: (data['photos'] as List?)?.map((e) => e.toString()).toList(),
      thumbnails: (data['thumbnails'] as List?)?.map((e) => e.toString()).toList(),
      isFavorite: favoritePetIds?.contains(id) ?? false,
      age: data['age']?.toString(),
      sellerId: data['sellerId']?.toString(),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(data['createdAt']))
          : null,
      isFeatured: data['isFeatured'] ?? false,
      breedInfo: data['breed'] is Map ? data['breed'] : null,
      categoryInfo: data['category'] is Map ? data['category'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breedInfo ?? breed,
      'category': categoryInfo ?? category,
      'description': description,
      'location': location,
      'gender': gender,
      'price': price,
      'photos': photos,
      'thumbnails': thumbnails,
      'age': age,
      'sellerId': sellerId,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'isFeatured': isFeatured,
    };
  }

  String getBreedName() {
    return breedInfo?['name'] ?? breed ?? 'Mixed Breed';
  }

  String getCategoryName() {
    return categoryInfo?['name'] ?? category ?? 'Unknown';
  }

  String getPrimaryImage() {
    if (photos != null && photos!.isNotEmpty) {
      return photos![0];
    }
    if (thumbnails != null && thumbnails!.isNotEmpty) {
      return thumbnails![0];
    }
    return 'assets/images/Banner 1.jpg'; // fallback image
  }

  PetModel copyWith({
    String? id,
    String? name,
    String? breed,
    String? category,
    String? description,
    String? location,
    String? gender,
    double? price,
    List<String>? photos,
    List<String>? thumbnails,
    bool? isFavorite,
    String? age,
    String? sellerId,
    DateTime? createdAt,
    bool? isFeatured,
    Map<String, dynamic>? breedInfo,
    Map<String, dynamic>? categoryInfo,
  }) {
    return PetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      gender: gender ?? this.gender,
      price: price ?? this.price,
      photos: photos ?? this.photos,
      thumbnails: thumbnails ?? this.thumbnails,
      isFavorite: isFavorite ?? this.isFavorite,
      age: age ?? this.age,
      sellerId: sellerId ?? this.sellerId,
      createdAt: createdAt ?? this.createdAt,
      isFeatured: isFeatured ?? this.isFeatured,
      breedInfo: breedInfo ?? this.breedInfo,
      categoryInfo: categoryInfo ?? this.categoryInfo,
    );
  }
}
