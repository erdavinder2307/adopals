import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../models/pet_model.dart';
import 'pet_details_screen.dart';
import 'common_app_bar.dart';
import '../services/modern_theme_service.dart';
import '../theme_service.dart';
import '../theme_service_provider.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  bool _isLoading = false;
  String _petsLabel = 'Recommended Pets...';
  List<PetModel> _pets = [];
  List<PetModel> _allPets = [];
  String _userName = 'Buyer';
  String? _userId; // TODO: Set this from auth
  List<String> _favoritePetIds = [];
  late ThemeService _themeService;
  bool _themeServiceInitialized = false;
  String _selectedFilter = 'All Pets';
  String _currentTheme = 'default-theme';
  bool _isDarkTheme = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_themeServiceInitialized) {
      _themeService = ThemeServiceProvider.of(context)!.themeService;
      _themeService.loadThemeFromDB();
      _themeServiceInitialized = true;
      _initializeTheme();
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _userName = user.displayName ?? user.email?.split('@').first ?? 'Buyer';
    }
    _initializeDashboard();
    
    // Listen to auth state changes like Angular service
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _userId) {
        // User changed, reinitialize
        setState(() {
          _userId = user.uid;
          _userName = user.displayName ?? user.email?.split('@').first ?? 'Buyer';
        });
        _initializeDashboard();
      } else if (user == null) {
        // User logged out
        setState(() {
          _userId = null;
          _userName = 'Buyer';
          _favoritePetIds = [];
          _allPets = [];
          _pets = [];
        });
      }
    });
  }

  void _initializeTheme() {
    _currentTheme = _themeService.activeTheme;
    _isDarkTheme = ModernThemeService.isDarkTheme(_currentTheme);
  }

  void _toggleTheme() {
    setState(() {
      _currentTheme = ModernThemeService.toggleDarkMode(_currentTheme);
      _isDarkTheme = ModernThemeService.isDarkTheme(_currentTheme);
      _themeService.setActiveTheme(_currentTheme);
    });
    _logAnalyticsEvent('theme_changed', {
      'theme': _currentTheme,
      'is_dark': _isDarkTheme,
    });
  }

  void _changeTheme(String theme) {
    setState(() {
      _currentTheme = theme;
      _isDarkTheme = ModernThemeService.isDarkTheme(theme);
      _themeService.setActiveTheme(theme);
    });
    _logAnalyticsEvent('theme_selected', {
      'theme': theme,
      'is_dark': _isDarkTheme,
    });
  }

  void getUpdatedUser() {
    // Method to refresh user data like Angular service
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
        _userName = user.displayName ?? user.email?.split('@').first ?? 'Buyer';
      });
      _fetchFavoritePetIds();
    }
  }

  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize favorites first
      await _fetchFavoritePetIds();
      
      // Then fetch pets
      await _fetchPets();
      
      // Log analytics like Angular version
      _logAnalyticsEvent('buyer_dashboard_view', {
        'user_id': _userId ?? 'anonymous',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'page_type': 'dashboard'
      });
      
    } catch (e) {
      print('Error initializing dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logAnalyticsEvent(String eventName, Map<String, dynamic> parameters) {
    // TODO: Implement Firebase Analytics logging
    print('Analytics Event: $eventName with parameters: $parameters');
  }

  Future<void> _fetchPets() async {
    setState(() => _isLoading = true);
    try {
      // Use real-time listener like Angular version
      FirebaseFirestore.instance
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((petsSnapshot) {
        final pets = petsSnapshot.docs.map((doc) {
          final data = doc.data();
          // Exclude pets created by current user if they're a buyer (like Angular)
          if (_userId != null && data['sellerId'] == _userId) {
            return null;
          }
          return PetModel.fromMap(data, doc.id, favoritePetIds: _favoritePetIds);
        }).where((pet) => pet != null).cast<PetModel>().toList();

        setState(() {
          _allPets = pets;
          _applyTabFilter();
          _isLoading = false;
        });
      }, onError: (error) {
        print('Error fetching pets: $error');
        setState(() => _isLoading = false);
      });
    } catch (e) {
      print('Error setting up pets listener: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFavoritePetIds() async {
    if (_userId == null) return;
    
    // Use real-time listener for favorites like Angular
    FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen((favSnapshot) {
      setState(() {
        _favoritePetIds = favSnapshot.docs.map((doc) => doc['petId'] as String).toList();
        // Re-apply filters when favorites change
        _applyTabFilter();
      });
    }, onError: (error) {
      print('Error fetching favorites: $error');
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      
      // Track search like Angular
      if (_searchQuery.isNotEmpty) {
        _logAnalyticsEvent('buyer_dashboard_search', {
          'search_query': _searchQuery,
          'tab_index': _selectedTabIndex,
          'tab_name': _getTabName(_selectedTabIndex),
          'user_id': _userId ?? 'anonymous'
        });
      }
      
      if (_searchQuery.isEmpty) {
        // Reset pagination when clearing search
        _currentPetsShown = _petsPerPage;
        _applyTabFilter();
      } else {
        // Apply search to the base filtered list from current tab
        List<PetModel> baseList;
        if (_selectedTabIndex == 0) {
          // AI Suggested: Use featured pets logic
          baseList = _allPets.where((pet) {
            return (pet.isFeatured == true) || 
                   (pet.photos != null && pet.photos!.isNotEmpty);
          }).toList();
          
          if (baseList.isEmpty) {
            baseList = _allPets.where((pet) => 
              pet.photos != null && pet.photos!.isNotEmpty
            ).toList();
          }
          
          if (baseList.length > 20) {
            baseList = baseList.take(20).toList();
          }
        } else if (_selectedTabIndex == 1) {
          baseList = _allPets; // All pets
        } else {
          baseList = _allPets.where((p) => _favoritePetIds.contains(p.id)).toList(); // Favorites
        }
        
        // Enhanced search matching like Angular
        _pets = baseList.where((pet) {
          String query = _searchQuery.toLowerCase();
          return _matchesSearch(pet, query);
        }).toList();
        
        _petsLabel = 'Search Results (${_pets.length})';
        
        // Log search results count
        _logAnalyticsEvent('buyer_dashboard_search_results', {
          'search_query': _searchQuery,
          'result_count': _pets.length,
          'tab_index': _selectedTabIndex,
          'tab_name': _getTabName(_selectedTabIndex),
          'user_id': _userId ?? 'anonymous'
        });
      }
    });
  }

  bool _matchesSearch(PetModel pet, String query) {
    // Enhanced search logic similar to Angular
    return pet.name.toLowerCase().contains(query) ||
           (pet.breed?.toLowerCase().contains(query) ?? false) ||
           (pet.category?.toLowerCase().contains(query) ?? false) ||
           (pet.location?.toLowerCase().contains(query) ?? false) ||
           (pet.description?.toLowerCase().contains(query) ?? false) ||
           (pet.gender?.toLowerCase().contains(query) ?? false) ||
           (pet.age?.toLowerCase().contains(query) ?? false);
  }

  void _onTabChanged(int index) {
    setState(() {
      final previousTabIndex = _selectedTabIndex;
      _selectedTabIndex = index;
      _currentPetsShown = _petsPerPage; // Reset pagination when switching tabs
      _searchQuery = ''; // Clear search query when switching tabs
      
      // Track tab change like Angular
      _logAnalyticsEvent('buyer_dashboard_tab_change', {
        'tab_index': index,
        'tab_name': _getTabName(index),
        'previous_tab': previousTabIndex,
        'user_id': _userId ?? 'anonymous'
      });
      
      _applyTabFilter();
    });
  }

  String _getTabName(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'AI Suggested';
      case 1:
        return 'All Pets';
      case 2:
        return 'Favorites';
      default:
        return 'Unknown';
    }
  }

  void _applyTabFilter() {
    List<PetModel> filteredPets;
    
    // Apply tab filter with AI logic like Angular
    if (_selectedTabIndex == 0) {
      _petsLabel = 'AI Suggested Pet...';
      // Prioritize featured pets or pets with photos (like Angular getFeaturedPets)
      filteredPets = _allPets.where((pet) {
        return (pet.isFeatured == true) || 
               (pet.photos != null && pet.photos!.isNotEmpty);
      }).toList();
      
      // If no featured pets, fallback to all pets with photos
      if (filteredPets.isEmpty) {
        filteredPets = _allPets.where((pet) => 
          pet.photos != null && pet.photos!.isNotEmpty
        ).toList();
      }
      
      // Limit to 20 pets like Angular
      if (filteredPets.length > 20) {
        filteredPets = filteredPets.take(20).toList();
      }
    } else if (_selectedTabIndex == 1) {
      _petsLabel = 'All Pets';
      filteredPets = _allPets;
    } else if (_selectedTabIndex == 2) {
      _petsLabel = 'Favorite Pets';
      filteredPets = _allPets.where((p) => _favoritePetIds.contains(p.id)).toList();
    } else {
      filteredPets = _allPets;
    }
    
    // Apply category filter
    if (_selectedFilter != 'All Pets') {
      filteredPets = filteredPets.where((pet) {
        final category = pet.category?.toLowerCase() ?? '';
        switch (_selectedFilter) {
          case 'Dogs':
            return category.contains('dog');
          case 'Cats':
            return category.contains('cat');
          case 'Birds':
            return category.contains('bird');
          case 'Others':
            return !category.contains('dog') && !category.contains('cat') && !category.contains('bird');
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply pagination limit
    int endIndex = math.min(_currentPetsShown, filteredPets.length);
    _pets = filteredPets.take(endIndex).toList();
  }

  int _petsPerPage = 8; // Load 8 pets at a time
  int _currentPetsShown = 8; // Initially show 8 pets

  void _loadMorePets() {
    setState(() {
      final previousCount = _currentPetsShown;
      _currentPetsShown = math.min(_currentPetsShown + _petsPerPage, _getAllFilteredPetsCount());
      
      // Track load more action like Angular
      _logAnalyticsEvent('buyer_dashboard_load_more_pets', {
        'new_total': _currentPetsShown,
        'previous_total': previousCount,
        'increment': _petsPerPage,
        'tab_index': _selectedTabIndex,
        'tab_name': _getTabName(_selectedTabIndex),
        'search_query': _searchQuery,
        'user_id': _userId ?? 'anonymous'
      });
      
      _applyTabFilter();
    });
  }

  int _getAllFilteredPetsCount() {
    List<PetModel> baseList;
    
    // Get base list from tab
    if (_selectedTabIndex == 0) {
      baseList = _allPets.where((pet) {
        return (pet.isFeatured == true) || 
               (pet.photos != null && pet.photos!.isNotEmpty);
      }).toList();
      
      // If no featured pets, fallback to all pets with photos
      if (baseList.isEmpty) {
        baseList = _allPets.where((pet) => 
          pet.photos != null && pet.photos!.isNotEmpty
        ).toList();
      }
      
      // Limit to 20 pets like Angular
      if (baseList.length > 20) {
        baseList = baseList.take(20).toList();
      }
    } else if (_selectedTabIndex == 1) {
      baseList = _allPets; // All pets
    } else {
      baseList = _allPets.where((p) => _favoritePetIds.contains(p.id)).toList(); // Favorites
    }
    
    // Apply category filter
    if (_selectedFilter != 'All Pets') {
      baseList = baseList.where((pet) {
        final category = pet.category?.toLowerCase() ?? '';
        switch (_selectedFilter) {
          case 'Dogs':
            return category.contains('dog');
          case 'Cats':
            return category.contains('cat');
          case 'Birds':
            return category.contains('bird');
          case 'Others':
            return !category.contains('dog') && !category.contains('cat') && !category.contains('bird');
          default:
            return true;
        }
      }).toList();
    }
    
    return baseList.length;
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;
    
    if (_searchQuery.isNotEmpty) {
      title = 'No pets found';
      subtitle = 'Try adjusting your search terms';
      icon = Icons.search_off;
    } else if (_selectedTabIndex == 2) {
      title = 'No favorites yet';
      subtitle = 'Start adding pets to your favorites';
      icon = Icons.favorite_border;
    } else {
      title = 'No pets available';
      subtitle = 'Check back later for new additions';
      icon = Icons.pets;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _selectedTabIndex,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: CommonAppBar(
          currentUserRole: 'buyer',
          cartCount: _favoritePetIds.length,
          notificationCount: 0,
          userName: _userName,
          userImage: null,
          onCartTap: () {
            // TODO: Navigate to cart
          },
          onProfileTap: () {
            // Handled by the AppBar's profile bottom sheet
          },
          onThemeTap: _toggleTheme,
          onNotificationTap: () {
            // TODO: Handle notifications
          },
          onLogoTap: () {
            // TODO: Navigate to home
          },
          onLogout: () {
            // TODO: Handle logout
          },
          onSwitchRole: () {
            // TODO: Handle role switch
          },
          onRegisterSeller: () {
            // TODO: Handle seller registration
          },
          isSeller: false,
          isDarkTheme: _isDarkTheme,
          themes: ModernThemeService.availableThemes,
          onThemeChange: _changeTheme,
        ),
        body: Column(
          children: [
            // Hero Section with Enhanced Design
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE066E0).withOpacity(0.15),
                    const Color(0xFF6C63FF).withOpacity(0.1),
                    Colors.white.withOpacity(0.95),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Stats Container
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_favoritePetIds.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE066E0),
                                ),
                              ),
                              Text(
                                'Favorites',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE066E0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE066E0).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: const Color(0xFFE066E0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Find your perfect companion with AI-powered recommendations',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Enhanced Search and Filter Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  prefixIcon: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                          onPressed: () => _onSearchChanged(''),
                                        )
                                      : null,
                                  hintText: 'Search by name, breed, location...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Quick Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('All Pets', Icons.pets, _selectedFilter == 'All Pets'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Dogs', Icons.pets, _selectedFilter == 'Dogs'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Cats', Icons.pets, _selectedFilter == 'Cats'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Birds', Icons.pets, _selectedFilter == 'Birds'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Others', Icons.more_horiz, _selectedFilter == 'Others'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Enhanced Tab Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tab Header with Count
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _petsLabel,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE066E0).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_pets.length} pets',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE066E0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Tab Bar with Enhanced Design
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              onTap: _onTabChanged,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey.shade600,
                              indicator: BoxDecoration(
                                color: const Color(0xFFE066E0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              indicatorPadding: const EdgeInsets.all(4),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 16),
                                      const SizedBox(width: 6),
                                      Text('AI Pick'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.grid_view, size: 16),
                                      const SizedBox(width: 6),
                                      Text('All'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.favorite, size: 16),
                                      const SizedBox(width: 6),
                                      Text('Saved'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Enhanced Tab Content
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Pet Grid with Smart Layout
                                _isLoading
                                    ? SizedBox(
                                        height: 200,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFE066E0),
                                          ),
                                        ),
                                      )
                                    : _pets.isEmpty
                                        ? SizedBox(
                                            height: 200,
                                            child: _buildEmptyState(),
                                          )
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 16,
                                                mainAxisSpacing: 16,
                                                childAspectRatio: 0.75, // Better ratio for content
                                              ),
                                              itemCount: _pets.length,
                                              itemBuilder: (context, index) {
                                                final pet = _pets[index];
                                                return _buildEnhancedPetCard(pet, index);
                                              },
                                            ),
                                
                                // Smart Load More with Analytics
                                if (_pets.length < _getAllFilteredPetsCount())
                                  Container(
                                    margin: const EdgeInsets.only(top: 20),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Showing ${_pets.length} of ${_getAllFilteredPetsCount()} pets',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          onPressed: _loadMorePets,
                                          icon: const Icon(Icons.expand_more, size: 18),
                                          label: const Text('Load More'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE066E0),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 8),
          child: FloatingActionButton.extended(
            onPressed: () {
              // TODO: Open AI chat assistant
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI Assistant coming soon!'),
                  backgroundColor: Color(0xFFE066E0),
                ),
              );
            },
            backgroundColor: const Color(0xFFE066E0),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'AI Help',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildEnhancedPetCard(PetModel pet, int index) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          color: Colors.white,
        ),
        child: InkWell(
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetDetailsScreen(
                  pet: pet,
                  userId: _userId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Pet Image with Badge
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: (pet.thumbnails != null && pet.thumbnails!.isNotEmpty)
                            ? Image.network(
                                pet.thumbnails![0],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return (pet.photos != null && pet.photos!.isNotEmpty)
                                      ? Image.network(
                                          pet.photos![0],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return _buildPlaceholderImage(pet.name);
                                          },
                                        )
                                      : _buildPlaceholderImage(pet.name);
                                },
                              )
                            : (pet.photos != null && pet.photos!.isNotEmpty)
                                ? Image.network(
                                    pet.photos![0],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderImage(pet.name);
                                    },
                                  )
                                : _buildPlaceholderImage(pet.name),
                      ),
                    ),
                    
                    // Featured Badge
                    if (pet.isFeatured == true)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Favorite Heart
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          pet.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: pet.isFavorite ? Colors.red : Colors.grey.shade600,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced Pet Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Minimize column size
                    children: [
                      // Pet Name
                      Flexible(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3), // Reduced spacing
                      
                      // Breed and Age Row
                      Flexible(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pet.breed ?? 'Mixed Breed',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pet.age != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE066E0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  pet.age!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFE066E0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4), // Reduced spacing
                      
                      // Location and Price Row
                      Flexible(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                pet.location ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pet.price != null)
                              Text(
                                '\$${pet.price!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE066E0),
                                ),
                              ),
                          ],
                        ),
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
  }

  Widget _buildPlaceholderImage(String petName) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            petName.isNotEmpty ? petName[0].toUpperCase() : 'P',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _currentPetsShown = _petsPerPage; // Reset pagination
          _applyTabFilter();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE066E0) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFE066E0) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
