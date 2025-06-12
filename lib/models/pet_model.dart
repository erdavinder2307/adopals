class PetModel {
  final String? estimateDeliveryTime;
  final String? customDeliveryTime;
  final List<dynamic>? favoriteBy;
  final double price;
  final int quantity;
  final String id;
  final String? name;
  final String? category;
  final String? breed;
  final String? vaccinationStatus;
  final String? purpose;
  final String? description;
  final String? saleOrAdoptionStatus;
  final String? owner;
  final String? gender;
  final String? location;
  final String? deliveryStatus;
  final List<String>? photos;
  final List<String>? thumbnails;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final DateTime? dob;
  final String availabilityStatus;
  final String? createdBy;
  final bool? isVerified;

  PetModel({
    this.estimateDeliveryTime,
    this.customDeliveryTime,
    this.favoriteBy,
    required this.price,
    required this.quantity,
    required this.id,
    this.name,
    this.category,
    this.breed,
    this.vaccinationStatus,
    this.purpose,
    this.description,
    this.saleOrAdoptionStatus,
    this.owner,
    this.gender,
    this.location,
    this.deliveryStatus,
    this.photos,
    this.thumbnails,
    this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.dob,
    required this.availabilityStatus,
    this.createdBy,
    this.isVerified,
  });

  factory PetModel.fromMap(Map<String, dynamic> data, String id, {List<String>? favoritePetIds}) {
    String? extractName(dynamic field) {
      if (field == null) return null;
      if (field is String) return field;
      if (field is Map && field['name'] != null) return field['name'].toString();
      if (field is Map && field['ref'] != null) return field['ref'].toString();
      // Firestore DocumentReference
      if (field.runtimeType.toString().contains('DocumentReference')) return field.toString();
      return field.toString();
    }
    return PetModel(
      estimateDeliveryTime: data['estimateDeliveryTime']?.toString(),
      customDeliveryTime: data['customDeliveryTime']?.toString(),
      favoriteBy: data['favoriteBy'] is List ? data['favoriteBy'] as List : [],
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] is double)
              ? data['price'] as double
              : (data['price'] is String)
                  ? double.tryParse(data['price']) ?? 0.0
                  : 0.0,
      quantity: (data['quantity'] is int)
          ? data['quantity'] as int
          : (data['quantity'] is String)
              ? int.tryParse(data['quantity']) ?? 1
              : 1,
      id: id,
      name: data['name'],
      category: extractName(data['category']),
      breed: extractName(data['breed']),
      vaccinationStatus: data['vaccinationStatus'],
      purpose: data['purpose'],
      description: data['description'],
      saleOrAdoptionStatus: data['saleOrAdoptionStatus'],
      owner: data['owner'],
      gender: data['gender'],
      location: data['location'],
      deliveryStatus: data['deliveryStatus'],
      photos: (data['photos'] as List?)?.map((e) => e.toString()).toList(),
      thumbnails: (data['thumbnails'] as List?)?.map((e) => e.toString()).toList(),
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt']
          : (data['createdAt'] is String)
              ? DateTime.tryParse(data['createdAt'])
              : null,
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt']
          : (data['updatedAt'] is String)
              ? DateTime.tryParse(data['updatedAt'])
              : null,
      isFavorite: favoritePetIds?.contains(id) ?? (data['isFavorite'] ?? false),
      dob: data['dob'] is DateTime
          ? data['dob']
          : (data['dob'] is String)
              ? DateTime.tryParse(data['dob'])
              : null,
      availabilityStatus: data['availabilityStatus'] ?? '',
      createdBy: data['createdBy'],
      isVerified: data['isVerified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimateDeliveryTime': estimateDeliveryTime,
      'customDeliveryTime': customDeliveryTime,
      'favoriteBy': favoriteBy,
      'price': price,
      'quantity': quantity,
      'id': id,
      'name': name,
      'category': category?.toString(),
      'breed': breed?.toString(),
      'vaccinationStatus': vaccinationStatus,
      'purpose': purpose,
      'description': description,
      'saleOrAdoptionStatus': saleOrAdoptionStatus,
      'owner': owner,
      'gender': gender,
      'location': location,
      'deliveryStatus': deliveryStatus,
      'photos': photos,
      'thumbnails': thumbnails,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'dob': dob?.toIso8601String(),
      'availabilityStatus': availabilityStatus,
      'createdBy': createdBy,
      'isVerified': isVerified,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  String? get age {
    if (dob == null) return null;
    final now = DateTime.now();
    int years = now.year - dob!.year;
    int months = now.month - dob!.month;
    int days = now.day - dob!.day;
    if (months < 0 || (months == 0 && days < 0)) {
      years--;
    }
    return years >= 0 ? years.toString() : null;
  }
}
