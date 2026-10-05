import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'home_screen.dart';
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

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) => sha256.convert(utf8.encode(input)).toString();

  Future<String?> _promptPassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm your password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<AuthCredential?> _getReauthCredential(User user) async {
    final providerId = user.providerData.isNotEmpty ? user.providerData.first.providerId : 'password';
    switch (providerId) {
      case 'google.com':
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        return GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      case 'apple.com':
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
          nonce: nonce,
        );
        return OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );
      case 'password':
      default:
        if (user.email == null) return null;
        final password = await _promptPassword();
        if (password == null || password.isEmpty) return null;
        return EmailAuthProvider.credential(email: user.email!, password: password);
    }
  }

  Future<void> _deleteUserData(String uid) async {
    final firestore = FirebaseFirestore.instance;

    final favorites = await firestore.collection('favorites').where('userId', isEqualTo: uid).get();
    final batch = firestore.batch();
    for (final doc in favorites.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(firestore.collection('carts').doc(uid));
    batch.delete(firestore.collection('users').doc(uid));
    await batch.commit();

    for (final imageUrl in [_profileImage, _coverImage]) {
      if (imageUrl == null || imageUrl.isEmpty) continue;
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {
        // Image may not be Storage-hosted or may already be gone; safe to ignore.
      }
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This permanently deletes your account, profile, favorites, and selected pets. This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final credential = await _getReauthCredential(user);
      if (credential == null) return; // user cancelled reauth
      await user.reauthenticateWithCredential(credential);

      await _deleteUserData(user.uid);
      await user.delete();
      await const FlutterSecureStorage().delete(key: 'email');
      await const FlutterSecureStorage().delete(key: 'password');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not delete account. Please try again.')),
      );
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
            // Stack to overlap profile picture half above cover image and above all below content
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Cover image at the top
                _coverImage != null
                    ? Image.network(_coverImage!, width: double.infinity, height: 180, fit: BoxFit.cover)
                    : Container(width: double.infinity, height: 180, color: Theme.of(context).colorScheme.surfaceVariant),
                // Profile picture, half above cover image, z-index above all
                Positioned(
                  bottom: -50, // Half of avatar radius
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Material(
                        elevation: 6,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _profileImage != null && _profileImage!.isNotEmpty
                              ? NetworkImage(_profileImage!)
                              : const AssetImage('assets/images/profile.jpg') as ImageProvider,
                        ),
                      ),
                      // Positioned(
                      //   right: -8,
                      //   bottom: -8,
                      //   child: Material(
                      //     elevation: 4,
                      //     shape: const CircleBorder(),
                      //     color: Colors.transparent,
                      //     child: IconButton(
                      //       icon: const Icon(Icons.edit),
                      //       color: Theme.of(context).colorScheme.primary,
                      //       onPressed: () {
                      //         // TODO: Implement cover/profile image update
                      //       },
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60), // Space for avatar overlap
            Text(_userName ?? '', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                // TODO: Navigate to adoptions
              },
              child: const Text('My Adoptions'),
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
                                      // Multi-select for categories
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: null,
                                        items: [
                                          ...['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'] // Example categories
                                              .map((cat) => DropdownMenuItem(
                                                    value: cat,
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          value: _categoriesPref.contains(cat),
                                                          onChanged: (checked) {
                                                            setState(() {
                                                              if (checked == true) {
                                                                if (!_categoriesPref.contains(cat)) _categoriesPref.add(cat);
                                                              } else {
                                                                _categoriesPref.remove(cat);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        Text(cat),
                                                      ],
                                                    ),
                                                  ))
                                        ],
                                        onChanged: (_) {},
                                        decoration: const InputDecoration(labelText: 'Categories'),
                                        selectedItemBuilder: (context) => _categoriesPref.map((e) => Text(e)).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      // Multi-select for breeds
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: null,
                                        items: [
                                          ...['Labrador', 'Persian', 'Parrot', 'Lionhead', 'Other'] // Example breeds
                                              .map((breed) => DropdownMenuItem(
                                                    value: breed,
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          value: _breedsPref.contains(breed),
                                                          onChanged: (checked) {
                                                            setState(() {
                                                              if (checked == true) {
                                                                if (!_breedsPref.contains(breed)) _breedsPref.add(breed);
                                                              } else {
                                                                _breedsPref.remove(breed);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        Text(breed),
                                                      ],
                                                    ),
                                                  ))
                                        ],
                                        onChanged: (_) {},
                                        decoration: const InputDecoration(labelText: 'Breeds'),
                                        selectedItemBuilder: (context) => _breedsPref.map((e) => Text(e)).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      // Multi-select for genders
                                      DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        value: null,
                                        items: [
                                          ...['Male', 'Female', 'Other'] // Example genders
                                              .map((gender) => DropdownMenuItem(
                                                    value: gender,
                                                    child: Row(
                                                      children: [
                                                        Checkbox(
                                                          value: _gendersPref.contains(gender),
                                                          onChanged: (checked) {
                                                            setState(() {
                                                              if (checked == true) {
                                                                if (!_gendersPref.contains(gender)) _gendersPref.add(gender);
                                                              } else {
                                                                _gendersPref.remove(gender);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                        Text(gender),
                                                      ],
                                                    ),
                                                  ))
                                        ],
                                        onChanged: (_) {},
                                        decoration: const InputDecoration(labelText: 'Genders'),
                                        selectedItemBuilder: (context) => _gendersPref.map((e) => Text(e)).toList(),
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
                  const SizedBox(height: 16),
                  // Danger Zone: account deletion (required for App Store Guideline 5.1.1(v))
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                          const SizedBox(height: 8),
                          const Text('Deleting your account removes your profile, favorites, and selected pets permanently.'),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            onPressed: _confirmAndDeleteAccount,
                            child: const Text('Delete Account'),
                          ),
                        ],
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
