import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/buyer_dashboard_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final PetModel pet;
  final String? userId;
  const PetDetailsScreen({Key? key, required this.pet, this.userId}) : super(key: key);

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  int _quantity = 1;
  bool _isInCart = false;
  bool _isFavorite = false;
  bool _isZoomModalOpen = false;
  int _currentIndex = 0;
  String? _zoomPhoto;
  String? _sellerName;
  String? _sellerId;
  double? _sellerRating;
  bool _loadingSeller = false;

  @override
  void initState() {
    super.initState();
    _fetchSellerInfo();
    // TODO: Check if pet is in cart/favorites
  }

  Future<void> _fetchSellerInfo() async {
    setState(() => _loadingSeller = true);
    try {
      final petData = widget.pet;
      if (petData != null && petData.id.isNotEmpty) {
        final petDoc = await FirebaseFirestore.instance.collection('pets').doc(petData.id).get();
        final sellerId = petDoc.data()?['createdBy'];
        if (sellerId != null) {
          _sellerId = sellerId;
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
          _sellerName = userDoc.data()?['name'] ?? 'Seller';
          // TODO: Fetch seller rating if available
        }
      }
    } catch (e) {
      // ignore
    }
    setState(() => _loadingSeller = false);
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _openZoomModal(String photo) {
    setState(() {
      _zoomPhoto = photo;
      _isZoomModalOpen = true;
    });
  }

  void _closeZoomModal() {
    setState(() {
      _isZoomModalOpen = false;
      _zoomPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carousel
              if (pet.photos != null && pet.photos!.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: pet.photos!.length,
                        controller: PageController(initialPage: _currentIndex),
                        onPageChanged: (i) => setState(() => _currentIndex = i),
                        itemBuilder: (context, i) {
                          final photo = pet.photos![i];
                          return GestureDetector(
                            onTap: () => _openZoomModal(photo),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(photo, fit: BoxFit.cover, width: double.infinity, height: 200),
                            ),
                          );
                        },
                      ),
                      if (pet.photos!.length > 1)
                        Positioned(
                          left: 0,
                          top: 90,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_left, size: 32),
                            onPressed: () {
                              setState(() {
                                _currentIndex = (_currentIndex == 0) ? pet.photos!.length - 1 : _currentIndex - 1;
                              });
                            },
                          ),
                        ),
                      if (pet.photos!.length > 1)
                        Positioned(
                          right: 0,
                          top: 90,
                          child: IconButton(
                            icon: const Icon(Icons.chevron_right, size: 32),
                            onPressed: () {
                              setState(() {
                                _currentIndex = (_currentIndex == pet.photos!.length - 1) ? 0 : _currentIndex + 1;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(pet.name, style: Theme.of(context).textTheme.headlineSmall),
              if (pet.breed != null) Text(pet.breed!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(pet.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_loadingSeller)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else if (_sellerName != null)
                    Text('Seller: $_sellerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (pet.price != null)
                    Text('₹${pet.price!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (pet.category != null) ...[
                    const SizedBox(width: 16),
                    Text('Category: ${pet.category!}'),
                  ],
                  if (pet.gender != null) ...[
                    const SizedBox(width: 16),
                    Text('Gender: ${pet.gender!}'),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Quantity:'),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _decreaseQuantity,
                  ),
                  Text('$_quantity'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _increaseQuantity,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Add to cart logic
                    },
                    child: Text(_isInCart ? 'View My Pack' : 'Add to Family'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Add to wishlist logic
                    },
                    child: const Text('Save for Home'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('PET DETAILS', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (pet.age != null) Text('Age: ${pet.age}'),
                  if (pet.category != null) Text('Category: ${pet.category}'),
                  if (pet.breed != null) Text('Breed: ${pet.breed}'),
                  if (pet.gender != null) Text('Gender: ${pet.gender}'),
                  if (pet.description != null) Text('Description: ${pet.description}'),
                ],
              ),
              // TODO: Delivery options, pin code check, etc.
              if (_isZoomModalOpen && _zoomPhoto != null)
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _closeZoomModal,
                      child: Container(
                        color: Colors.black54,
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Image.network(_zoomPhoto!),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 32),
                        onPressed: _closeZoomModal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
