import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../block_service.dart';
import '../models/pet_model.dart';
import '../report_service.dart';
import '../screens/buyer_dashboard_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final PetModel pet;
  final String? userId;
  const PetDetailsScreen({Key? key, required this.pet, this.userId}) : super(key: key);

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
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
          _sellerName = userDoc.data()?['name'] ?? 'Pet Giver';
          // TODO: Fetch seller rating if available
        }
      }
    } catch (e) {
      // ignore
    }
    setState(() => _loadingSeller = false);
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

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(userId);
    final cartDoc = await cartRef.get();
    List<dynamic> items = cartDoc.data()?['items'] ?? [];
    final petId = widget.pet.id;
    final existingIndex = items.indexWhere((item) => item['id'] == petId);
    if (existingIndex == -1) {
      // One pet per adoption request — matches web app's adoption model
      final petMap = {
        ...widget.pet.toMap(),
        'quantity': 1,
      };
      items.add(petMap);
    }
    await cartRef.set({'items': items}, SetOptions(merge: true));
    setState(() {
      _isInCart = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pet added')),
    );
  }

  Future<void> _addToFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userId = user.uid;
    final favRef = FirebaseFirestore.instance.collection('favorites');
    final snapshot = await favRef.where('userId', isEqualTo: userId).where('petId', isEqualTo: widget.pet.id).get();
    if (snapshot.docs.isEmpty) {
      await favRef.add({'userId': userId, 'petId': widget.pet.id});
      setState(() {
        _isFavorite = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pet added to favorites')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pet is already in your favorites')),
      );
    }
  }

  String? get _giverId => _sellerId ?? petGiverId(widget.pet);

  Future<void> _reportListing() async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Please sign in to report a listing.')));
      return;
    }
    final result = await showDialog<({String reason, String details})>(
      context: context,
      builder: (context) => const _ReportListingDialog(),
    );
    if (result == null) return;
    try {
      await submitPetReport(buildPetReport(
        petId: widget.pet.id,
        sellerId: _giverId,
        reason: result.reason,
        details: result.details,
        reporterId: user.uid,
      ));
      messenger.showSnackBar(
        const SnackBar(content: Text('Thanks — our team will review this listing within 24 hours.')),
      );
    } catch (e) {
      debugPrint('Could not submit report: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send your report. Please try again.')),
      );
    }
  }

  Future<void> _blockGiver() async {
    final giverId = _giverId;
    final messenger = ScaffoldMessenger.of(context);
    if (giverId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not find the pet giver for this listing.')));
      return;
    }
    if (giverId == FirebaseAuth.instance.currentUser?.uid) {
      messenger.showSnackBar(const SnackBar(content: Text('This is your own listing.')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this giver?'),
        content: Text(
          'You will no longer see pets listed by ${_sellerName ?? 'this pet giver'}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BlockService.instance.block(giverId);
      messenger.showSnackBar(const SnackBar(content: Text('Pet giver blocked. Their pets are now hidden.')));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Could not block giver: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Could not block this pet giver. Please try again.')));
    }
  }

  Widget _buildAdoptionFeeSection(PetModel pet) {
    final fee = pet.adoptionFee;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (fee == null) {
      return Row(
        children: [
          if (pet.saleOrAdoptionStatus != null && pet.saleOrAdoptionStatus!.isNotEmpty) ...[
            Text(pet.saleOrAdoptionStatus!, style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor)),
            const SizedBox(width: 10),
          ],
          Text(
            pet.price > 0 ? '₹${pet.price.toStringAsFixed(0)}' : 'Free',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ],
      );
    }

    final statusLabel = pet.saleOrAdoptionStatus == 'Sale' ? 'Adoption (with Fees)' : 'Adoption';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(statusLabel, style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor)),
            const SizedBox(width: 10),
            Text(
              fee.isFree ? 'Free' : '₹${fee.totalFee.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ],
        ),
        if (!fee.isFree) ...[
          const SizedBox(height: 8),
          Text('Adoption Fee Breakdown', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 4),
          if (fee.careRecoveryFee > 0) Text('Care & Recovery Fee: ₹${fee.careRecoveryFee.toStringAsFixed(0)}'),
          if ((fee.vaccinationFee ?? 0) > 0) Text('Vaccination Fee: ₹${fee.vaccinationFee!.toStringAsFixed(0)}'),
          if ((fee.microchipFee ?? 0) > 0) Text('Microchip Fee: ₹${fee.microchipFee!.toStringAsFixed(0)}'),
          if ((fee.otherFee ?? 0) > 0) Text('Other Fee: ₹${fee.otherFee!.toStringAsFixed(0)}'),
          if ((fee.platformFee ?? 0) > 0) Text('Platform Fee: ₹${fee.platformFee!.toStringAsFixed(0)}'),
          const SizedBox(height: 4),
          Text('Total Fee: ₹${fee.totalFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name ?? ''),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'report') _reportListing();
              if (value == 'block') _blockGiver();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'report',
                child: ListTile(leading: Icon(Icons.flag_outlined), title: Text('Report this listing')),
              ),
              PopupMenuItem(
                value: 'block',
                child: ListTile(leading: Icon(Icons.block), title: Text('Block this giver')),
              ),
            ],
          ),
        ],
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
              Text(pet.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
              if (pet.breed != null) Text(pet.breed!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(pet.description ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_loadingSeller)
                    const CircularProgressIndicator(strokeWidth: 2)
                  else if (_sellerName != null)
                    Text('Pet Giver: $_sellerName', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              _buildAdoptionFeeSection(pet),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (pet.category != null)
                    Text('Category: ${pet.category!}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.gender != null) ...[
                    const SizedBox(width: 16),
                    Text('Gender: ${pet.gender!}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text('One pet per adoption request', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: _addToCart,
                    child: Text(_isInCart ? 'View My Pack' : 'Add to Family'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    onPressed: _addToFavorites,
                    child: Text(_isFavorite ? 'Saved' : 'Save for Home'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('PET DETAILS', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (pet.age != null) Text('Age: ${pet.age}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.category != null) Text('Category: ${pet.category}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.breed != null) Text('Breed: ${pet.breed}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.gender != null) Text('Gender: ${pet.gender}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.color != null) Text('Color: ${pet.color}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.size != null) Text('Size: ${pet.size}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.weightValue != null && pet.weightUnit != null)
                    Text('Weight: ${pet.weightValue} ${pet.weightUnit}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.temperament != null) Text('Temperament: ${pet.temperament}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.vaccinationStatus != null) Text('Vaccination: ${pet.vaccinationStatus}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.medicalHistory != null) Text('Medical History: ${pet.medicalHistory}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.microchipped != null) Text('Microchipped: ${pet.microchipped! ? 'Yes' : 'No'}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.goodWithKids != null) Text('Good With Kids: ${pet.goodWithKids! ? 'Yes' : 'No'}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.goodWithOtherPets != null) Text('Good With Other Pets: ${pet.goodWithOtherPets! ? 'Yes' : 'No'}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.spayedNeutered != null) Text('Spayed/Neutered: ${pet.spayedNeutered! ? 'Yes' : 'No'}', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  if (pet.description != null) Text('Description: ${pet.description}', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              // Note: Pet Relocation (pin-code estimate/service areas) and Breed Wikipedia info
              // exist on the web app's pet details page but require new service integrations
              // not yet built in this app — out of scope for this pass.
              if (_isZoomModalOpen && _zoomPhoto != null)
                Builder(
                  builder: (context) {
                    Future.microtask(() {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(16),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(_zoomPhoto!, fit: BoxFit.contain),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                onPressed: () {
                                  _closeZoomModal();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportListingDialog extends StatefulWidget {
  const _ReportListingDialog();

  @override
  State<_ReportListingDialog> createState() => _ReportListingDialogState();
}

class _ReportListingDialogState extends State<_ReportListingDialog> {
  String? _reason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report this listing'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final reason in reportReasons)
                    RadioListTile<String>(
                      value: reason,
                      title: Text(reason),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop((reason: _reason!, details: _detailsController.text)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
