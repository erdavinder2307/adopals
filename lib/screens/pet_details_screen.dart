import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../adoption_request_service.dart';
import '../auth_guard.dart';
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
  final AdoptionRequestService _adoptionRequests = AdoptionRequestService();
  bool _requestSent = false;
  bool _checkingRequest = false;
  bool _sendingRequest = false;
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
    _checkExistingRequest();
  }

  /// Shows "Request sent" instead of the button when the adopter already has an open request for this pet.
  Future<void> _checkExistingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.pet.id.isEmpty) return;
    setState(() => _checkingRequest = true);
    try {
      final exists = await _adoptionRequests.hasOpenRequest(applicantId: user.uid, petId: widget.pet.id);
      if (mounted) setState(() => _requestSent = exists);
    } catch (e) {
      debugPrint('Could not check existing adoption requests: $e');
    } finally {
      if (mounted) setState(() => _checkingRequest = false);
    }
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

  Future<void> _requestToAdopt() async {
    if (!requireSignIn(context, message: 'Sign in to send an adoption request.')) return;
    final user = FirebaseAuth.instance.currentUser!;
    final messenger = ScaffoldMessenger.of(context);
    final giverId = _sellerId ?? widget.pet.createdBy;
    if (giverId == null || giverId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not load the pet giver for this listing. Please try again.')),
      );
      return;
    }
    if (giverId == user.uid) {
      messenger.showSnackBar(const SnackBar(content: Text('This is your own listing.')));
      return;
    }
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AdoptionRequestSheet(petName: widget.pet.name),
    );
    if (message == null || !mounted) return;

    setState(() => _sendingRequest = true);
    try {
      // Re-check so a second device or a double tap cannot create a duplicate request.
      final exists = await _adoptionRequests.hasOpenRequest(applicantId: user.uid, petId: widget.pet.id);
      if (!exists) {
        await _adoptionRequests.submitRequest(
          pet: widget.pet,
          giverId: giverId,
          giverName: _sellerName ?? 'Pet Giver',
          applicantId: user.uid,
          applicantName: user.displayName,
          applicantEmail: user.email,
          message: message,
        );
      }
      if (!mounted) return;
      setState(() => _requestSent = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(exists
              ? 'You already sent a request for this pet. The giver will contact you.'
              : 'Request sent. The giver will contact you.'),
        ),
      );
    } catch (e) {
      debugPrint('Could not send adoption request: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not send your request. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _sendingRequest = false);
    }
  }

  Widget _buildRequestButton() {
    final colors = Theme.of(context).colorScheme;
    if (_requestSent) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
        ),
        onPressed: null,
        icon: const Icon(Icons.check),
        label: const Text('Request sent'),
      );
    }
    final busy = _checkingRequest || _sendingRequest || _loadingSeller;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      onPressed: busy ? null : _requestToAdopt,
      child: _sendingRequest
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Request to adopt'),
    );
  }

  Future<void> _addToFavorites() async {
    if (!requireSignIn(context, message: 'Sign in to save pets for home.')) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;
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
    if (!requireSignIn(context, message: 'Sign in to report a listing.')) return;
    final user = FirebaseAuth.instance.currentUser!;
    final messenger = ScaffoldMessenger.of(context);
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
    if (!requireSignIn(context, message: 'Sign in to block a pet giver.')) return;
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
              // Guests see the public projection, which has no fee fields: do not show "Free".
              if (FirebaseAuth.instance.currentUser != null) _buildAdoptionFeeSection(pet),
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
                  _buildRequestButton(),
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

/// Bottom sheet with a short message to the pet giver. Pops with the message on Send.
class _AdoptionRequestSheet extends StatefulWidget {
  const _AdoptionRequestSheet({this.petName});

  final String? petName;

  @override
  State<_AdoptionRequestSheet> createState() => _AdoptionRequestSheetState();
}

class _AdoptionRequestSheetState extends State<_AdoptionRequestSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: defaultAdoptionMessage(widget.petName));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = normalizeAdoptionMessage(_controller.text);
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.petName == null || widget.petName!.trim().isEmpty) ? 'this pet' : widget.petName!.trim();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Request to adopt $name', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Send a short message to the pet giver. They will contact you about the next steps. '
              'No payment is taken in the app. Your name and email are shared with the giver so they can contact you.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: adoptionMessageMaxLength,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message to the pet giver',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => ElevatedButton(
                    onPressed: value.text.trim().isEmpty ? null : _send,
                    child: const Text('Send request'),
                  ),
                ),
              ],
            ),
          ],
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
