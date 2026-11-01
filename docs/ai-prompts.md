# Reusable AI Prompts

Copy/adapt these when starting a task. Each assumes `../CLAUDE.md` is already loaded — don't re-explain the architecture in the prompt.

## Feature implementation (new screen)
> Implement `<screen>` in `lib/screens/`. Follow the existing convention: `StatefulWidget`, `snake_case.dart` filename matching the class, Firestore calls made directly from `State` methods (no repository layer exists — see `docs/flutter.md`). Add it to the `routes` map in `main.dart` if it needs to be reachable by name, otherwise push it via `MaterialPageRoute`.

## Bug fixing
> Reproduce `<bug>` in `<screen/service>`. Check `docs/firebase.md` for the actual Firestore field shape before assuming a field exists — several fields (`category`, `breed`) can arrive as string, map, or `DocumentReference` and are defensively parsed in `PetModel`.

## Cart feature work
> Note: `lib/models/cart_item.dart`, `lib/services/cart_service.dart`, and `lib/screens/cart_screen.dart` are empty stubs. Current cart logic lives inline in `pet_details_screen.dart` against the `carts` Firestore collection. If asked to build out cart functionality, these three stub files are the intended target — don't assume they already have logic.

## Firebase / Firestore changes
> This project shares a Firebase project (`animalpedia-4f75b`) and Firestore data with `../adopals-app` (the Angular web app). Before changing a collection's field shape, check `../adopals-app/CLAUDE.md` and its Firestore-touching services so both apps stay compatible.

## State management changes
> This app uses a hand-rolled `ChangeNotifier` + `InheritedWidget` pattern (`ThemeService`/`ThemeServiceProvider`), not Provider/Riverpod/Bloc. Extend that pattern rather than introducing a new state package unless explicitly asked to migrate.

## Testing
> `test/widget_test.dart` is a stale default-template test that will fail if run — see `docs/testing.md` before assuming `flutter test` should be green. Fix/remove it before adding new coverage, and prefer starting with pure-logic tests (`PetModel`) since there's no mocking setup for Firebase yet.

## Build / release
> No CI/CD, no Android release signing (`key.properties`), no iOS `exportOptions.plist` exist yet — see `docs/deployment.md`. Treat any signing/CI request as new setup, not a fix to an existing pipeline.

## Localization
> Not configured — no `flutter_localizations`, `intl`, or `.arb` files. Adding localization is a from-scratch setup (see `docs/flutter.md`).

## FVM / Flutter version pinning
> Not configured — no `.fvmrc`. Last known working Flutter revision is in `.metadata` (`5874a72aa4c779a02553007c47dacbefba2374dc`, stable channel). Setting up FVM means introducing it fresh.
