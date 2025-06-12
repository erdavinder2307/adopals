import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pet_details_screen.dart'; // Import the PetDetailsScreen
import 'common_app_bar.dart';
import '../../theme_service.dart';
import '../../theme_service_provider.dart';
import '../models/pet_model.dart';

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
  List<PetModel> _favoritePets = [];
  List<PetModel> _recentlyViewedPets = [];
  String _userName = 'Buyer';
  String? _userId; // TODO: Set this from auth
  List<String> _favoritePetIds = [];
  late ThemeService _themeService;
  bool _themeServiceInitialized = false;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_themeServiceInitialized) {
      _themeService = ThemeServiceProvider.of(context)!.themeService;
      _themeService.loadThemeFromDB();
      _themeServiceInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _userName = user.displayName ?? user.email?.split('@').first ?? 'Buyer';
    } else {
      // If not logged in, redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true);
    await _fetchFavoritePetIds();
    await _fetchPets();
    //await _fetchRecentlyViewedPets();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPets() async {
    setState(() => _isLoading = true);
    try {
      final petsSnapshot = await FirebaseFirestore.instance.collection('pets').orderBy('createdAt', descending: true).get();
      final pets = petsSnapshot.docs.map((doc) {
        final data = doc.data();
        // Defensive: ensure all required fields are present and types are correct
        return PetModel.fromMap(data, doc.id, favoritePetIds: _favoritePetIds);
      }).where((pet) => pet != null).toList();
      setState(() {
        _allPets = pets;
        _applyTabFilter();
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('Error fetching pets: $e\n$st');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchFavoritePetIds() async {
    if (_userId == null) return;
    final favSnapshot = await FirebaseFirestore.instance.collection('favorites').where('userId', isEqualTo: _userId).get();
    setState(() {
      _favoritePetIds = favSnapshot.docs.map((doc) => doc['petId'] as String).toList();
      _favoritePets = _allPets.where((p) => _favoritePetIds.contains(p.id)).toList();
    });
  }

  Future<void> _fetchRecentlyViewedPets() async {
    if (_userId == null) return;
    final recentSnapshot = await FirebaseFirestore.instance
        .collection('recently-viewed-pets')
        .where('userId', isEqualTo: _userId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    final petIds = recentSnapshot.docs.map((doc) => doc['petId'] as String).toList();
    if (petIds.isEmpty) {
      setState(() => _recentlyViewedPets = []);
      return;
    }
    final petsSnapshot = await FirebaseFirestore.instance.collection('pets').where(FieldPath.documentId, whereIn: petIds).get();
    setState(() {
      _recentlyViewedPets = petsSnapshot.docs.map((doc) => PetModel.fromMap(doc.data(), doc.id, favoritePetIds: _favoritePetIds)).toList();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _pets = _allPets.where((pet) => (pet.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      _applyTabFilter();
    });
  }

  void _applyTabFilter() {
    if (_selectedTabIndex == 0) {
      _petsLabel = 'Recommended Pets...';
      _pets = _allPets;
    } else if (_selectedTabIndex == 1) {
      _petsLabel = 'All Pets';
      _pets = _allPets;
    } else if (_selectedTabIndex == 2) {
      _petsLabel = 'Favorite Pets';
      _pets = _allPets.where((p) => _favoritePetIds.contains(p.id)).toList();
    }
    // Ensure search filter is applied after tab filter
    if (_searchQuery.isNotEmpty) {
      _pets = _pets.where((pet) => (pet.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
  }

  void _loadMorePets() {
    // TODO: Implement pagination or load more logic
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    await _secureStorage.delete(key: 'email');
    await _secureStorage.delete(key: 'password');
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _selectedTabIndex,
      child: Scaffold(
        appBar: CommonAppBar(
          currentUserRole: 'buyer',
          cartCount: _favoritePetIds.length,
          notificationCount: 0,
          userName: _userName,
          userImage: null,
          onCartTap: () {},
          onProfileTap: () {},
          onThemeTap: () {
            setState(() {
              final current = _themeService.activeTheme;
              final isDark = _themeService.isDarkTheme;
              final newTheme = isDark
                  ? current.replaceAll('-dark', '')
                  : '${current}-dark';
              _themeService.setActiveTheme(newTheme);
            });
          },
          onNotificationTap: () {},
          onLogoTap: () {},
          onLogout: _logout,
          onSwitchRole: () {},
          onRegisterSeller: () {},
          isSeller: false,
          isDarkTheme: _themeService.isDarkTheme,
          themes: ThemeService.themes,
          onThemeChange: (theme) {
            setState(() {
              _themeService.setActiveTheme(theme);
            });
          },
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find your furry forever friend. Explore AdoPals today.', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search for the pets',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            // TODO: Show filter dialog
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      onTap: _onTabChanged,
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.purple,
                      tabs: const [
                        Tab(text: 'Recommended'),
                        Tab(text: 'All Pets'),
                        Tab(text: 'Favorites'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_petsLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _pets.isEmpty
                              ? const Center(child: Text('No records found.'))
                              : ListView.builder(
                                  itemCount: _pets.length,
                                  itemBuilder: (context, index) {
                                    final pet = _pets[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: ListTile(
                                        leading: (pet.thumbnails != null && pet.thumbnails!.isNotEmpty)
                                            ? CircleAvatar(backgroundImage: NetworkImage(pet.thumbnails![0]))
                                            : (pet.photos != null && pet.photos!.isNotEmpty)
                                                ? CircleAvatar(backgroundImage: NetworkImage(pet.photos![0]))
                                                : CircleAvatar(child: Text((pet.name != null && (pet.name?.isNotEmpty ?? false)) ? pet.name![0] : '?')),
                                        title: Text(pet.name ?? ''),
                                        subtitle: Text(pet.breed ?? ''),
                                        trailing: Icon(
                                          pet.isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: pet.isFavorite ? Colors.red : null,
                                        ),
                                        onTap: () async {
                                          // Navigate to pet details screen
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
                                      ),
                                    );
                                  },
                                ),
                    ),
                    if (_pets.length < _allPets.length)
                      Center(
                        child: ElevatedButton(
                          onPressed: _loadMorePets,
                          child: const Text('Load More'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Side content: Recently Viewed
            // Expanded(
            //   flex: 1,
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text('Recently Viewed', style: Theme.of(context).textTheme.titleMedium),
            //         const SizedBox(height: 8),
            //         Expanded(
            //           child: _recentlyViewedPets.isEmpty
            //               ? const Text('No records found.')
            //               : ListView(
            //                   children: _recentlyViewedPets
            //                       .map((pet) => ListTile(
            //                             leading: CircleAvatar(child: Text(pet.name[0])),
            //                             title: Text(pet.name),
            //                             subtitle: Text(pet.breed ?? ''),
            //                           ))
            //                       .toList(),
            //                 ),
            //         ),
            //         if (_recentlyViewedPets.length < _allPets.length)
            //           TextButton(
            //             onPressed: () {
            //               // TODO: Load more recently viewed
            //             },
            //             child: const Text('Load More'),
            //           ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Open chat
          },
          backgroundColor: Colors.purple,
          child: const Icon(Icons.chat),
        ),
      ),
    );
  }
}
