import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme_service.dart';
import '../../theme_service_provider.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({Key? key}) : super(key: key);

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  final _aboutFormKey = GlobalKey<FormState>();
  final _prefFormKey = GlobalKey<FormState>();
  bool _aboutEditMode = false;
  bool _prefEditMode = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userAddress;
  String? _profileImage;
  String? _coverImage;
  List<String> _categoriesPref = [];
  List<String> _breedsPref = [];
  List<String> _gendersPref = [];
  double _minAge = 0;
  double _maxAge = 100;
  late ThemeService _themeService;
  bool _themeServiceInitialized = false;

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
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      //_userName = user.displayName ?? '';
      //_userEmail = user.email ?? '';
      // Fetch more user data from Firestore if needed
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
      final data = userDoc.data();
      setState(() {
        _userName = data?['name'] ?? _userName;
        _userEmail = data?['email'] ?? _userEmail;
        _userPhone = data?['phone'] ?? '';
        _userAddress = data?['address'] ?? '';
        _profileImage = data?['buyerImage'];
        _coverImage = data?['buyerCoverImage'];
        _categoriesPref = (data?['categoriesPref'] as List?)?.map((e) => e['name'].toString()).toList() ?? [];
        _breedsPref = (data?['breedsPref'] as List?)?.map((e) => e['name'].toString()).toList() ?? [];
        _gendersPref = (data?['gendersPref'] as List?)?.map((e) => e.toString()).toList() ?? [];
        _minAge = (data?['ageRange']?['minAge'] ?? 0).toDouble();
        _maxAge = (data?['ageRange']?['maxAge'] ?? 100).toDouble();
      });
    }
  }

  void _toggleAboutEditMode() {
    setState(() => _aboutEditMode = !_aboutEditMode);
  }

  void _togglePrefEditMode() {
    setState(() => _prefEditMode = !_prefEditMode);
  }

  void _saveAboutInfo() async {
    if (_aboutFormKey.currentState?.validate() ?? false) {
      _aboutFormKey.currentState?.save();
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'name': _userName,
        'email': _userEmail,
        'phone': _userPhone,
        'address': _userAddress,
      });
      setState(() => _aboutEditMode = false);
    }
  }

  void _savePrefInfo() async {
    if (_prefFormKey.currentState?.validate() ?? false) {
      _prefFormKey.currentState?.save();
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'categoriesPref': _categoriesPref.map((e) => {'name': e}).toList(),
        'breedsPref': _breedsPref.map((e) => {'name': e}).toList(),
        'gendersPref': _gendersPref,
        'ageRange': {'minAge': _minAge, 'maxAge': _maxAge},
      });
      setState(() => _prefEditMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                _coverImage != null
                    ? Image.network(_coverImage!, width: double.infinity, height: 180, fit: BoxFit.cover)
                    : Container(width: double.infinity, height: 180, color: Theme.of(context).colorScheme.surfaceVariant),
                Positioned(
                  left: 24,
                  top: 120,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                        ? NetworkImage(_profileImage!)
                        : const AssetImage('assets/images/profile.jpg') as ImageProvider,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 140,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      // TODO: Implement cover/profile image update
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_userName ?? '', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                // TODO: Navigate to orders
              },
              child: const Text('My Orders'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // About Section
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _aboutFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: _toggleAboutEditMode,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _aboutEditMode
                                ? Column(
                                    children: [
                                      TextFormField(
                                        initialValue: _userName,
                                        decoration: const InputDecoration(labelText: 'Name'),
                                        onSaved: (v) => _userName = v,
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                      TextFormField(
                                        initialValue: _userEmail,
                                        decoration: const InputDecoration(labelText: 'Email'),
                                        onSaved: (v) => _userEmail = v,
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                      TextFormField(
                                        initialValue: _userPhone,
                                        decoration: const InputDecoration(labelText: 'Phone'),
                                        onSaved: (v) => _userPhone = v,
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                      TextFormField(
                                        initialValue: _userAddress,
                                        decoration: const InputDecoration(labelText: 'Address'),
                                        onSaved: (v) => _userAddress = v,
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                        onPressed: _saveAboutInfo,
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Name: ${_userName ?? ''}'),
                                      Text('Email: ${_userEmail ?? ''}'),
                                      Text('Phone: ${_userPhone ?? ''}'),
                                      Text('Address: ${_userAddress ?? ''}'),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Preferences Section
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _prefFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pet Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: _togglePrefEditMode,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _prefEditMode
                                ? Column(
                                    children: [
                                      TextFormField(
                                        initialValue: _categoriesPref.join(', '),
                                        decoration: const InputDecoration(labelText: 'Categories (comma separated)'),
                                        onSaved: (v) => _categoriesPref = v?.split(',').map((e) => e.trim()).toList() ?? [],
                                      ),
                                      TextFormField(
                                        initialValue: _breedsPref.join(', '),
                                        decoration: const InputDecoration(labelText: 'Breeds (comma separated)'),
                                        onSaved: (v) => _breedsPref = v?.split(',').map((e) => e.trim()).toList() ?? [],
                                      ),
                                      TextFormField(
                                        initialValue: _gendersPref.join(', '),
                                        decoration: const InputDecoration(labelText: 'Genders (comma separated)'),
                                        onSaved: (v) => _gendersPref = v?.split(',').map((e) => e.trim()).toList() ?? [],
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: _minAge.toString(),
                                              decoration: const InputDecoration(labelText: 'Min Age'),
                                              keyboardType: TextInputType.number,
                                              onSaved: (v) => _minAge = double.tryParse(v ?? '0') ?? 0,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: _maxAge.toString(),
                                              decoration: const InputDecoration(labelText: 'Max Age'),
                                              keyboardType: TextInputType.number,
                                              onSaved: (v) => _maxAge = double.tryParse(v ?? '100') ?? 100,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                        onPressed: _savePrefInfo,
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Categories: ${_categoriesPref.join(', ')}'),
                                      Text('Breeds: ${_breedsPref.join(', ')}'),
                                      Text('Genders: ${_gendersPref.join(', ')}'),
                                      Text('Age Range: $_minAge - $_maxAge'),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
