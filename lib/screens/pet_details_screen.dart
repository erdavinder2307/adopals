import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pet_model.dart';
import '../services/pets_service.dart';

class PetDetailsScreen extends StatefulWidget {
  final PetModel pet;
  final String? userId;
  const PetDetailsScreen({Key? key, required this.pet, this.userId}) : super(key: key);

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> with TickerProviderStateMixin {
  final bool _isInCart = false;
  bool _isZoomModalOpen = false;
  int _currentIndex = 0;
  String? _zoomPhoto;
  String? _sellerName;
  bool _loadingSeller = false;
  bool _petDataLoading = true;
  bool _breedInfoLoading = true;
  bool _isCheckingPinCode = false;
  
  // Enhanced pet data structure to match Angular
  Map<String, dynamic> _petData = {};
  Map<String, dynamic>? _sellerInfo;
  List<String> _sellerDeliveryAreas = [];
  Map<String, dynamic>? _breedInfo;
  Map<String, dynamic>? _relocationEstimate;
  
  // Controllers and form data
  final TextEditingController _pinCodeController = TextEditingController();
  String _pinCodeStatus = '';
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PetsService _petsService = PetsService();

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    // Initialize pet data from the passed pet model
    _initializePetData();
    _fetchSellerInfo();
    _fetchBreedInfo();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  void _initializePetData() {
    setState(() {
      _petDataLoading = true;
    });
    
    // Convert PetModel to enhanced data structure
    _petData = {
      'id': widget.pet.id,
      'name': widget.pet.name,
      'description': widget.pet.description ?? '',
      'photos': widget.pet.photos ?? [],
      'thumbnails': widget.pet.thumbnails ?? [],
      'category': widget.pet.categoryInfo ?? {'name': widget.pet.category ?? ''},
      'breed': widget.pet.breedInfo ?? {'name': widget.pet.breed ?? ''},
      'gender': widget.pet.gender,
      'price': widget.pet.price,
      'age': widget.pet.age,
      'sellerId': widget.pet.sellerId,
      'rating': 0.0, // Will be updated with seller rating
      'saleOrAdoptionStatus': widget.pet.price != null ? 'Sale' : 'Adoption',
      // Extended fields that may not be in the basic model
      'color': '',
      'size': '',
      'weightValue': null,
      'weightUnit': '',
      'temperament': '',
      'vaccinationStatus': '',
      'medicalHistory': '',
      'microchipped': null,
      'goodWithKids': null,
      'goodWithOtherPets': null,
      'spayedNeutered': null,
      'dob': null,
      // Adoption fee structure
      'adoptionFee': null,
    };
    
    setState(() {
      _petDataLoading = false;
    });
    
    // Fetch additional data from Firestore if pet ID exists
    if (widget.pet.id != null) {
      _fetchEnhancedPetData();
    }
  }

  Future<void> _fetchEnhancedPetData() async {
    try {
      final petDoc = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.pet.id)
          .get();
      
      if (petDoc.exists) {
        final data = petDoc.data()!;
        setState(() {
          _petData = {
            ..._petData,
            ...data,
            'id': widget.pet.id,
          };
        });
      }
    } catch (e) {
      print('Error fetching enhanced pet data: $e');
    }
  }

  Future<void> _fetchSellerInfo() async {
    setState(() => _loadingSeller = true);
    try {
      final sellerId = widget.pet.sellerId ?? _petData['createdBy'];
      if (sellerId != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
        if (userDoc.exists) {
          final sellerData = userDoc.data()!;
          setState(() {
            _sellerName = sellerData['name'] ?? 'Pet Giver';
            _sellerInfo = sellerData;
            _sellerDeliveryAreas = List<String>.from(sellerData['deliveryAreas'] ?? []);
          });
          
          // Calculate seller rating
          _calculateSellerRating(sellerId);
        }
      }
    } catch (e) {
      print('Error fetching seller info: $e');
    }
    setState(() => _loadingSeller = false);
  }

  Future<void> _calculateSellerRating(String sellerId) async {
    try {
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('sellerId', isEqualTo: sellerId)
          .get();
      
      if (reviewsQuery.docs.isNotEmpty) {
        double totalRating = 0;
        int count = 0;
        
        for (var doc in reviewsQuery.docs) {
          final rating = doc.data()['rating'];
          if (rating != null) {
            totalRating += rating.toDouble();
            count++;
          }
        }
        
        if (count > 0) {
          setState(() {
            _petData['rating'] = totalRating / count;
          });
        }
      }
    } catch (e) {
      print('Error calculating seller rating: $e');
    }
  }

  Future<void> _fetchBreedInfo() async {
    setState(() => _breedInfoLoading = true);
    try {
      final breedName = _petData['breed']?['name'] ?? widget.pet.breed;
      if (breedName != null && breedName.isNotEmpty) {
        // Simulate breed info fetch (replace with actual implementation)
        setState(() {
          _breedInfo = {
            'breedName': breedName,
            'sellerNotes': 'This is a wonderful breed known for its friendly nature.',
            'wikipediaSummary': 'This breed is known for its loyalty and intelligence...',
            'wikipediaUrl': 'https://en.wikipedia.org/wiki/$breedName',
          };
        });
      }
    } catch (e) {
      print('Error fetching breed info: $e');
    }
    setState(() => _breedInfoLoading = false);
  }

  void _checkPinCode() {
    final pin = _pinCodeController.text.trim();
    
    if (pin.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(pin)) {
      setState(() {
        _pinCodeStatus = 'Please enter a valid 6-digit pincode.';
        _relocationEstimate = null;
      });
      return;
    }

    if (_sellerDeliveryAreas.isEmpty) {
      setState(() {
        _pinCodeStatus = 'Pet giver has not specified relocation areas. Please contact them directly.';
        _relocationEstimate = null;
      });
      return;
    }

    setState(() {
      _isCheckingPinCode = true;
      _pinCodeStatus = 'Checking pet relocation availability...';
      _relocationEstimate = null;
    });

    // Simulate relocation check (replace with actual implementation)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCheckingPinCode = false;
          _relocationEstimate = {
            'isRelocatable': true,
            'estimatedDays': 3,
            'message': 'Pet relocation available to this area!',
            'nearestRelocationArea': 'Main City Area',
            'additionalInfo': 'Standard relocation service available',
            'isOutsideServiceArea': false,
            'serviceZone': 'standard',
          };
          _pinCodeStatus = '✅ ${_relocationEstimate!['message']}';
        });
      }
    });
  }

  String _getAgeFromDob(dynamic dob) {
    if (dob == null) return '';
    
    DateTime? birthDate;
    if (dob is String) {
      birthDate = DateTime.tryParse(dob);
    } else if (dob is DateTime) {
      birthDate = dob;
    } else if (dob is Timestamp) {
      birthDate = dob.toDate();
    }
    
    if (birthDate == null) return '';
    
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    
    if (months < 0) {
      years--;
      months += 12;
    }
    
    if (years > 0) {
      return months > 0 
        ? '$years yr${years > 1 ? 's' : ''} $months month${months > 1 ? 's' : ''}'
        : '$years yr${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return 'Less than 1 month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Show loading state while pet data is loading
    if (_petDataLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_petData['name'] ?? widget.pet.name),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildImageCarousel(theme),
                    _buildPetDetailsCard(theme),
                    if (_breedInfo != null) _buildBreedInfoCard(theme),
                    const SizedBox(height: 80), // Extra space for FAB
                  ],
                ),
              ),
            ),
          ),
          
          // Zoom modal overlay
          if (_isZoomModalOpen && _zoomPhoto != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        maxScale: 3.0,
                        child: Image.network(
                          _zoomPhoto!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: CircleAvatar(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _closeZoomModal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isZoomModalOpen ? null : FloatingActionButton.extended(
        onPressed: () {
          // Add to cart/family action using _petsService for analytics
          _petsService.logPetView(
            widget.pet.id ?? '',
            widget.pet.name,
            widget.pet.category ?? '',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isInCart ? 'Pet already in your pack!' : 'Pet added to family!'),
              backgroundColor: theme.primaryColor,
            ),
          );
        },
        icon: Icon(_isInCart ? Icons.visibility : Icons.favorite),
        label: Text(_isInCart ? 'View My Pack' : 'Add to Family'),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildImageCarousel(ThemeData theme) {
    final photos = _petData['photos'] as List<dynamic>? ?? [];
    
    if (photos.isEmpty) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No images available',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 320,
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            controller: PageController(initialPage: _currentIndex),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => _openZoomModal(photo),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photo,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (photos.length > 1) ...[
            Positioned(
              left: 8,
              top: 150,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: _prevSlide,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 150,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: _nextSlide,
                ),
              ),
            ),
          ],
          // Page indicators
          if (photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: photos.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? theme.primaryColor
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _prevSlide() {
    final photos = _petData['photos'] as List<dynamic>? ?? [];
    if (photos.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex == 0) ? photos.length - 1 : _currentIndex - 1;
      });
    }
  }

  void _nextSlide() {
    final photos = _petData['photos'] as List<dynamic>? ?? [];
    if (photos.isNotEmpty) {
      setState(() {
        _currentIndex = (_currentIndex == photos.length - 1) ? 0 : _currentIndex + 1;
      });
    }
  }

  Widget _buildPetDetailsCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet name and description
          Text(
            _petData['name'] ?? widget.pet.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (_petData['description']?.isNotEmpty == true)
            Text(
              _petData['description'],
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          const SizedBox(height: 16),

          // Seller information
          _buildSellerSection(theme),
          const SizedBox(height: 16),

          // Price/Adoption information
          _buildPriceSection(theme),
          const SizedBox(height: 16),

          // Adoption info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'One pet per adoption request',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          _buildActionButtons(theme),
          const SizedBox(height: 20),

          // Pet details section
          _buildPetDetailsSection(theme),
          const SizedBox(height: 20),

          // Relocation section
          _buildRelocationSection(theme),
        ],
      ),
    );
  }

  Widget _buildSellerSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Giver:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                if (_loadingSeller)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    _sellerName ?? 'Pet Giver',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (_petData['rating'] != null && _petData['rating'] > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _petData['rating'].toStringAsFixed(1),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            onPressed: () {
              // Start chat with seller - use seller info if available
              final sellerName = _sellerInfo?['name'] ?? _sellerName ?? 'Pet Giver';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chat with $sellerName coming soon!')),
              );
            },
            icon: Icon(Icons.chat, color: theme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    final adoptionFee = _petData['adoptionFee'];
    final price = _petData['price'];
    final status = _petData['saleOrAdoptionStatus'] ?? 'Adoption';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (adoptionFee != null)
                Text(
                  adoptionFee['isFree'] == true ? 'Free' : '₹${adoptionFee['totalFee']}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                )
              else if (price != null)
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
            ],
          ),
          if (adoptionFee != null && adoptionFee['isFree'] != true) ...[
            const SizedBox(height: 12),
            Text(
              'Adoption Fee Breakdown',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeeBreakdown(adoptionFee, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown(Map<String, dynamic> adoptionFee, ThemeData theme) {
    final fees = [
      if (adoptionFee['careRecoveryFee'] != null) 'Care & Recovery Fee: ₹${adoptionFee['careRecoveryFee']}',
      if (adoptionFee['vaccinationFee'] != null) 'Vaccination Fee: ₹${adoptionFee['vaccinationFee']}',
      if (adoptionFee['microchipFee'] != null) 'Microchip Fee: ₹${adoptionFee['microchipFee']}',
      if (adoptionFee['supportFee'] != null) 'Support Fee: ₹${adoptionFee['supportFee']}',
      if (adoptionFee['foodAndCareFee'] != null) 'Food & Care Fee: ₹${adoptionFee['foodAndCareFee']}',
      if (adoptionFee['groomingFee'] != null) 'Grooming Fee: ₹${adoptionFee['groomingFee']}',
      if (adoptionFee['transportFee'] != null) 'Transport Fee: ₹${adoptionFee['transportFee']}',
      if (adoptionFee['paperworkFee'] != null) 'Paperwork Fee: ₹${adoptionFee['paperworkFee']}',
      if (adoptionFee['otherFee'] != null) 'Other Fee: ₹${adoptionFee['otherFee']}',
      if (adoptionFee['platformFee'] != null) 'Platform Fee (10%): ₹${adoptionFee['platformFee']}',
    ];

    return Column(
      children: fees.map((fee) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fee,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isInCart ? 'Pet already in your pack!' : 'Pet added to family!'),
                  backgroundColor: theme.primaryColor,
                ),
              );
            },
            icon: Icon(_isInCart ? Icons.visibility : Icons.favorite),
            label: Text(_isInCart ? 'View My Pack' : 'Add to Family'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to wishlist!')),
              );
            },
            icon: const Icon(Icons.bookmark_outline),
            label: const Text('Save for Home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
              side: BorderSide(color: theme.colorScheme.secondary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetDetailsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: theme.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'PET DETAILS',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPetAttributesList(theme),
      ],
    );
  }

  Widget _buildPetAttributesList(ThemeData theme) {
    final attributes = <Widget>[];

    // Age
    if (_petData['dob'] != null) {
      attributes.add(_buildPetAttribute(Icons.cake, 'Age', _getAgeFromDob(_petData['dob']), theme));
    } else if (_petData['age'] != null) {
      attributes.add(_buildPetAttribute(Icons.cake, 'Age', _petData['age'].toString(), theme));
    }

    // Category
    if (_petData['category']?['name'] != null) {
      attributes.add(_buildPetAttribute(Icons.category, 'Category', _petData['category']['name'], theme));
    }

    // Breed
    if (_petData['breed']?['name'] != null) {
      attributes.add(_buildPetAttribute(Icons.pets, 'Breed', _petData['breed']['name'], theme));
    }

    // Gender
    if (_petData['gender'] != null) {
      attributes.add(_buildPetAttribute(Icons.wc, 'Gender', _petData['gender'], theme));
    }

    // Color
    if (_petData['color'] != null && _petData['color'].toString().isNotEmpty) {
      attributes.add(_buildPetAttribute(Icons.palette, 'Color', _petData['color'], theme));
    }

    // Size
    if (_petData['size'] != null && _petData['size'].toString().isNotEmpty) {
      attributes.add(_buildPetAttribute(Icons.straighten, 'Size', _petData['size'], theme));
    }

    // Weight
    if (_petData['weightValue'] != null && _petData['weightUnit'] != null) {
      attributes.add(_buildPetAttribute(Icons.fitness_center, 'Weight', '${_petData['weightValue']} ${_petData['weightUnit']}', theme));
    }

    // Temperament
    if (_petData['temperament'] != null && _petData['temperament'].toString().isNotEmpty) {
      attributes.add(_buildPetAttribute(Icons.emoji_people, 'Temperament', _petData['temperament'], theme));
    }

    // Vaccination Status
    if (_petData['vaccinationStatus'] != null && _petData['vaccinationStatus'].toString().isNotEmpty) {
      attributes.add(_buildPetAttribute(Icons.local_hospital, 'Vaccination', _petData['vaccinationStatus'], theme));
    }

    // Medical History
    if (_petData['medicalHistory'] != null && _petData['medicalHistory'].toString().isNotEmpty) {
      attributes.add(_buildPetAttribute(Icons.healing, 'Medical History', _petData['medicalHistory'], theme));
    }

    // Microchipped
    if (_petData['microchipped'] != null) {
      attributes.add(_buildPetAttribute(Icons.verified_user, 'Microchipped', _petData['microchipped'] ? 'Yes' : 'No', theme));
    }

    // Good with kids
    if (_petData['goodWithKids'] != null) {
      attributes.add(_buildPetAttribute(Icons.child_care, 'Good With Kids', _petData['goodWithKids'] ? 'Yes' : 'No', theme));
    }

    // Good with other pets
    if (_petData['goodWithOtherPets'] != null) {
      attributes.add(_buildPetAttribute(Icons.pets, 'Good With Other Pets', _petData['goodWithOtherPets'] ? 'Yes' : 'No', theme));
    }

    // Spayed/Neutered
    if (_petData['spayedNeutered'] != null) {
      attributes.add(_buildPetAttribute(Icons.content_cut, 'Spayed/Neutered', _petData['spayedNeutered'] ? 'Yes' : 'No', theme));
    }

    return Column(children: attributes);
  }

  Widget _buildPetAttribute(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_shipping, color: theme.primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Pet Relocation Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Pin code input
        TextField(
          controller: _pinCodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Enter Pin Code',
            hintText: 'Pin Code',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: _isCheckingPinCode
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _checkPinCode,
                    icon: Icon(Icons.search, color: theme.primaryColor),
                  ),
          ),
        ),
        
        if (_pinCodeStatus.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _pinCodeStatus,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _pinCodeStatus.startsWith('✅') ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        // Relocation estimate
        if (_relocationEstimate != null && _relocationEstimate!['isRelocatable'] == true) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pets, color: theme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Pet Relocation Estimate',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_relocationEstimate!['estimatedDays']}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _relocationEstimate!['estimatedDays'] == 1 ? 'Day' : 'Days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_relocationEstimate!['nearestRelocationArea'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place, color: theme.primaryColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'From: ${_relocationEstimate!['nearestRelocationArea']}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if (_relocationEstimate!['additionalInfo'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.primaryColor, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _relocationEstimate!['additionalInfo'],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Seller delivery areas
        if (_sellerDeliveryAreas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Pet Giver Relocates To:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sellerDeliveryAreas.map((area) => Chip(
              label: Text(
                area,
                style: theme.textTheme.bodySmall,
              ),
              backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
              side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBreedInfoCard(ThemeData theme) {
    if (_breedInfoLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, color: theme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Breed Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_breedInfo!['sellerNotes'] != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, color: theme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller Notes:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _breedInfo!['sellerNotes'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          if (_breedInfo!['wikipediaSummary'] != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: theme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'More Info:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _breedInfo!['wikipediaSummary'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Full breed info coming soon!')),
                          );
                        },
                        child: const Text('See Full Breed Info'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openZoomModal(String photo) {
    setState(() {
      _zoomPhoto = photo;
      _isZoomModalOpen = true;
    });
  }

  void _closeZoomModal() {
    if (mounted && _isZoomModalOpen) {
      setState(() {
        _isZoomModalOpen = false;
        _zoomPhoto = null;
      });
    }
  }
}
