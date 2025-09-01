import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pet_model.dart';
import '../services/pets_service.dart';
import '../widgets/adoption_step_widget.dart';
import 'authentication/login_screen.dart';

class MobileLandingPage extends StatefulWidget {
  const MobileLandingPage({super.key});

  @override
  State<MobileLandingPage> createState() => _MobileLandingPageState();
}

class _MobileLandingPageState extends State<MobileLandingPage>
    with TickerProviderStateMixin {
  final PetsService _petsService = PetsService();
  final PageController _pageController = PageController();
  
  int _currentSlide = 0;
  Timer? _slideTimer;
  List<PetModel> _featuredPets = [];
  bool _isLoadingPets = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Hero carousel data matching Angular app
  final List<Map<String, String>> _heroImages = [
    {
      'image': 'assets/images/Banner 1.jpg',
      'title': 'Find Your Perfect Pet Companion',
      'subtitle': 'A loving home for every pet'
    },
    {
      'image': 'assets/images/Banner 2.jpg', 
      'title': 'A loving home for every pet',
      'subtitle': 'Your perfect match is just a click away'
    },
    {
      'image': 'assets/images/Banner 3.jpg',
      'title': 'Your perfect match is just a click away',
      'subtitle': 'Discover amazing pets waiting for you'
    }
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _startAutoSlide();
    _loadFeaturedPets();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _slideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentSlide < _heroImages.length - 1) {
        _currentSlide++;
      } else {
        _currentSlide = 0;
      }
      _pageController.animateToPage(
        _currentSlide,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoSlide() {
    _slideTimer?.cancel();
  }

  void _resumeAutoSlide() {
    _startAutoSlide();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentSlide = index;
    });
  }

  void _goToSlide(int index) {
    _pauseAutoSlide();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 3), () {
      _resumeAutoSlide();
    });
  }

  Future<void> _loadFeaturedPets() async {
    try {
      final pets = await _petsService.getPetsWithFallback(limit: 3);
      setState(() {
        _featuredPets = pets;
        _isLoadingPets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPets = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _viewPetDetails(PetModel pet) {
    if (pet.id != null) {
      _petsService.logPetView(pet.id!, pet.name, pet.getCategoryName());
      _navigateToLogin(); // Navigate to login since user needs to authenticate
    }
  }

  void _addToFavorites(PetModel pet) {
    if (pet.id != null) {
      _navigateToLogin(); // Navigate to login for authentication
    }
  }

  void _sharePet(PetModel pet) {
    if (pet.id != null) {
      _petsService.sharePet(pet.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pet shared!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildValueProposition(),
                _buildPetShowcase(),
                _buildHowItWorks(),
                _buildFooterCTA(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: [
          // Hero carousel
          GestureDetector(
            onTapDown: (_) => _pauseAutoSlide(),
            onTapUp: (_) => Future.delayed(const Duration(seconds: 3), _resumeAutoSlide),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _heroImages.length,
              itemBuilder: (context, index) {
                final heroItem = _heroImages[index];
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(heroItem['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation arrows
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  final newIndex = _currentSlide == 0 ? _heroImages.length - 1 : _currentSlide - 1;
                  _goToSlide(newIndex);
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: () {
                  final newIndex = _currentSlide == _heroImages.length - 1 ? 0 : _currentSlide + 1;
                  _goToSlide(newIndex);
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
              ),
            ),
          ),
          
          // Slide indicators
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _heroImages.asMap().entries.map((entry) {
                return GestureDetector(
                  onTap: () => _goToSlide(entry.key),
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentSlide == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Hero overlay content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _heroImages[_currentSlide]['title']!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _heroImages[_currentSlide]['subtitle']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text('Adopt a Pet Today'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueProposition() {
    final benefits = [
      {
        'icon': Icons.verified_user,
        'title': 'Verified Pet Givers',
        'description': 'All our Pet Givers are verified for your safety',
        'svgIcon': 'assets/icons/pet-giver.svg'
      },
      {
        'icon': Icons.security,
        'title': 'Safe Adoptions',
        'description': 'Secure process with guided support',
        'svgIcon': null
      },
      {
        'icon': Icons.home,
        'title': 'Find Forever Homes',
        'description': 'Connect pets with loving families',
        'svgIcon': 'assets/icons/adoption-home.svg'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Why Choose Adopals?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1 : 4,
            ),
            itemCount: benefits.length,
            itemBuilder: (context, index) {
              final benefit = benefits[index];
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Use SVG icon if available, otherwise use Material Icon
                      benefit['svgIcon'] != null
                          ? SvgPicture.asset(
                              benefit['svgIcon'] as String,
                              width: 32,
                              height: 32,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColor,
                                BlendMode.srcIn,
                              ),
                            )
                          : Icon(
                              benefit['icon'] as IconData,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                      const SizedBox(height: 8),
                      Text(
                        benefit['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        benefit['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPetShowcase() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Pets',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _navigateToLogin,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingPets
              ? _buildPetLoadingGrid()
              : _featuredPets.isEmpty
                  ? _buildNoPetsMessage()
                  : _buildPetGrid(),
        ],
      ),
    );
  }

  Widget _buildPetLoadingGrid() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: Column(
                children: [
                  Container(
                    height: 100,
                    color: Colors.grey.shade300,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Container(
                          height: 16,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          width: 80,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoPetsMessage() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              child: Image.asset(
                'assets/images/hero-pet.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.pets,
                    size: 48,
                    color: Colors.grey.shade400,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No pets available right now',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new companions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToLogin,
              child: const Text('Explore More'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetGrid() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredPets.length,
        itemBuilder: (context, index) {
          final pet = _featuredPets[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _viewPetDetails(pet),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet image
                    Container(
                      height: 100,
                      width: double.infinity,
                      child: pet.photos != null && pet.photos!.isNotEmpty
                          ? Image.network(
                              pet.photos![0],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/Banner 1.jpg',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/Banner 1.jpg',
                              fit: BoxFit.cover,
                            ),
                    ),
                    // Pet info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pet.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pet.getBreedName(),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => _addToFavorites(pet),
                                  child: Icon(
                                    Icons.favorite_border,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _sharePet(pet),
                                  child: Icon(
                                    Icons.share,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Text(
            'How Adopals Works',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // For mobile, use vertical layout with step widgets
          MediaQuery.of(context).size.width < 600
              ? Column(
                  children: [
                    AdoptionStepWidget(
                      stepNumber: '1',
                      title: 'Find Pets',
                      description: 'Browse through verified pet profiles and find your perfect match',
                      imagePath: 'assets/images/get-started-1.png',
                    ),
                    const SizedBox(height: 16),
                    AdoptionStepWidget(
                      stepNumber: '2',
                      title: 'Connect',
                      description: 'Message Pet Givers directly and arrange meetings',
                      imagePath: 'assets/images/get-started-2.png',
                    ),
                    const SizedBox(height: 16),
                    AdoptionStepWidget(
                      stepNumber: '3',
                      title: 'Adopt',
                      description: 'Complete the adoption process with our guided support',
                      imagePath: 'assets/images/get-started-3.png',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: AdoptionStepWidget(
                        stepNumber: '1',
                        title: 'Find Pets',
                        description: 'Browse through verified pet profiles and find your perfect match',
                        imagePath: 'assets/images/get-started-1.png',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdoptionStepWidget(
                        stepNumber: '2',
                        title: 'Connect',
                        description: 'Message Pet Givers directly and arrange meetings',
                        imagePath: 'assets/images/get-started-2.png',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdoptionStepWidget(
                        stepNumber: '3',
                        title: 'Adopt',
                        description: 'Complete the adoption process with our guided support',
                        imagePath: 'assets/images/get-started-3.png',
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildFooterCTA() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'Ready to Find Your Perfect Pet?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Join to find companions through Adopals',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Start Adoption Request',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
