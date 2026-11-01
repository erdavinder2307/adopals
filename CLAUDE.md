# adopals — Flutter Mobile App

Early-stage Flutter mobile companion to the web platform in `../adopals-app/`. See [../CLAUDE.md](../CLAUDE.md) for the wider repo map.

## Scope
Buyer-side flows only so far: `lib/screens/` has `home`, `get_started`, `buyer_dashboard`, `buyer_profile`, `pet_details`, `authentication/login`, plus a `cart` screen that is currently an **empty stub** (see [docs/flutter.md](docs/flutter.md)). No seller/admin flows exist yet in this app — those live only in `adopals-app`.

## Key facts (details in linked docs)
- **Architecture, widget/naming conventions, state management, routing, themes, assets, localization, build_runner, FVM** → [docs/flutter.md](docs/flutter.md)
- **Firebase project, Auth providers, Firestore collections/models** → [docs/firebase.md](docs/firebase.md)
- **Android/iOS build & release commands, CI/CD, troubleshooting** → [docs/deployment.md](docs/deployment.md)
- **Test conventions and current (broken) test state** → [docs/testing.md](docs/testing.md)
- **Reusable task prompts** → [docs/ai-prompts.md](docs/ai-prompts.md)

## Fast facts worth keeping top-of-mind
- No external state or routing package — hand-rolled `ChangeNotifier`/`InheritedWidget` + `MaterialApp` named routes.
- No FVM, no CI/CD, no build_runner, no localization currently set up — any of these is a from-scratch task, not an extension.
- `test/widget_test.dart` is a stale default-template test that fails if run.
- Shares the `animalpedia-4f75b` Firebase project and Firestore data with `../adopals-app` — coordinate schema changes across both.

## Commands
- Run: `flutter run` or `./dev.sh` (interactive simulator/emulator picker).
- Analyze: `flutter analyze`.
- Test: `flutter test` (currently red — see [docs/testing.md](docs/testing.md)).

## Generated/ignore
Never read or edit generated content for source changes: `build/`, `.dart_tool/`, `ios/Pods/`, `android/build/`, `coverage/`, plus platform scaffolding (`macos/`, `windows/`, `linux/`, `web/`) unless the task specifically requires platform config.
