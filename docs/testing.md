# Testing

## Current state
- `test/widget_test.dart` is the **unmodified default Flutter counter-app template** — it tests for a counter UI (`find.text('0')`, tapping `Icons.add`) that doesn't exist in this app anymore. **This test will fail if run** (`flutter test`) since `MyApp` was rewritten to a real app without removing/updating the scaffold test. Treat it as stale, not as a real regression check.
- No other tests exist — no widget tests for real screens, no unit tests for `PetModel`/`ThemeService`, no integration tests, no `integration_test/` directory.

## Conventions (to establish, none exist yet)
- Standard Flutter test layout: mirror `lib/` structure under `test/` (e.g. `test/models/pet_model_test.dart` for `lib/models/pet_model.dart`).
- Use `flutter_test`'s `testWidgets` for widget tests, plain `test()` for pure logic (e.g. `PetModel.fromMap` parsing, `ThemeService` theme resolution).
- No mocking package (`mockito`, `mocktail`) is in `pubspec.yaml` yet — adding one is a prerequisite for testing anything that touches `FirebaseAuth`/`FirebaseFirestore`, since screens currently call `FirebaseFirestore.instance` directly rather than through an injectable/mockable service layer (see [flutter.md](flutter.md) — this is the main structural obstacle to real unit tests).

## Commands
- `flutter test` — runs everything under `test/` (currently just the stale counter test, which will fail).
- `flutter test test/some_test.dart` — run a single file once tests exist.

## Recommended first steps if asked to add real test coverage
1. Fix or delete `test/widget_test.dart` first so `flutter test` isn't red by default.
2. Start with `PetModel.fromMap`/`toJson` — pure logic, no Firebase mocking needed, highest value for the defensive type-parsing it does (see [firebase.md](firebase.md)).
3. Only introduce a mocking package once a screen/service needs `FirebaseAuth`/`FirebaseFirestore` test doubles.
