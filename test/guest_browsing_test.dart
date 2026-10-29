import 'package:adopals/auth_guard.dart';
import 'package:adopals/models/pet_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign-in prompt opens the login route and clears the stack', (tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {'/login': (context) => const Scaffold(body: Text('LOGIN'))},
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSignInPrompt(context, message: 'Sign in to save pets for home.'),
            child: const Text('Save for Home'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Save for Home'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to save pets for home.'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Save for Home'), findsNothing);
  });

  test('publicPets document maps to a PetModel', () {
    final pet = PetModel.fromPublicPet({
      'name': 'Bruno',
      'type': 'Dog',
      'breed': 'Labrador',
      'gender': 'Male',
      'location': 'Bengaluru, Karnataka, India',
      'photoUrl': 'https://example.com/p.jpg',
      'thumbnailUrl': 'https://example.com/t.jpg',
      'status': 'available',
      'featured': true,
    }, 'pet1');

    expect(pet.id, 'pet1');
    expect(pet.name, 'Bruno');
    expect(pet.category, 'Dog');
    expect(pet.breed, 'Labrador');
    expect(pet.photos, ['https://example.com/p.jpg']);
    expect(pet.thumbnails, ['https://example.com/t.jpg']);
    expect(pet.price, 0);
    expect(pet.adoptionFee, isNull);
    expect(pet.isFavorite, isFalse);
  });

  test('publicPets document without photos has no photo lists', () {
    final pet = PetModel.fromPublicPet({'name': 'Kitty'}, 'pet2');
    expect(pet.photos, isNull);
    expect(pet.thumbnails, isNull);
  });
}
