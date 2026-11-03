// Signs the AI tester's test account in on the emulator, so its screenshot and
// test runs start signed in. Run only by ai-tester-tools
// (`refresh-sessions mobile adopals`), which pushes the values file and
// passes its path as AIT_VALUES_FILE; the contract is in that tool's README.
// The tool reads exactly one "AIT_RESULT: <result>" line from the output.
// Firebase Auth keeps the session on the device; the tool runs this test with
// --no-uninstall so the app (and the session) stay installed afterwards.
// ignore_for_file: avoid_print

import 'package:adopals/firebase_options.dart';
import 'package:adopals/main.dart';
import 'package:adopals/screens/authentication/login_screen.dart';
import 'package:adopals/screens/buyer_dashboard_screen.dart';
import 'package:adopals/screens/get_started_screen.dart';
import 'package:adopals/theme_service.dart';
import 'package:adopals/theme_service_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'ait_values.dart';

bool _printed = false;

void _result(String result, [String? note]) {
  // The note is for a person reading the log; it never holds a value.
  if (note != null) print('AIT_NOTE: $note');
  print('AIT_RESULT: $result');
  _printed = true;
}

Future<bool> _pumpUntil(WidgetTester tester, bool Function() done,
    {Duration timeout = const Duration(seconds: 60)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (done()) return true;
  }
  return false;
}

bool _shows(Type type) => find.byType(type).evaluate().isNotEmpty;

Future<void> _signIn(WidgetTester tester) async {
  final values = takeAitValues(const String.fromEnvironment('AIT_VALUES_FILE'));
  if (values == null) {
    _result('failed', 'values file missing or incomplete');
    fail('values file missing or incomplete');
  }

  // The same start-up as main().
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final current = await FirebaseAuth.instance
      .authStateChanges()
      .first
      .timeout(const Duration(seconds: 20), onTimeout: () => null);
  if (current != null) {
    if (sameEmail(current.email, values.expectedEmail)) {
      _result('already-signed-in');
      return;
    }
    // Never sign someone else's account out.
    _result('wrong-account');
    fail('signed in as another account');
  }

  final themeService = ThemeService();
  await themeService.loadThemeFromDB();
  await tester.pumpWidget(ThemeServiceProvider(
    themeService: themeService,
    child: const MyApp(),
  ));

  // The app opens on the get-started pages; Skip goes to the login screen.
  if (!await _pumpUntil(tester, () => _shows(GetStartedScreen))) {
    _result('failed', 'get-started screen did not appear');
    fail('get-started screen did not appear');
  }
  await tester.tap(find.text('Skip'));
  if (!await _pumpUntil(tester, () => _shows(LoginScreen))) {
    _result('failed', 'login screen did not appear');
    fail('login screen did not appear');
  }
  await tester.pumpAndSettle();

  await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'), values.email);
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'), values.password);
  // "Remember me" would store the password in the app's secure storage; keep
  // it off (ticked only when an earlier run of the app saved credentials).
  final rememberMe = find.byType(Checkbox);
  if (rememberMe.evaluate().isNotEmpty &&
      tester.widget<Checkbox>(rememberMe.first).value == true) {
    await tester.tap(rememberMe.first);
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final signIn = find.widgetWithText(ElevatedButton, 'SIGN IN');
  await tester.ensureVisible(signIn);
  await tester.pumpAndSettle();
  await tester.tap(signIn);

  await _pumpUntil(tester, () => _shows(BuyerDashboardScreen));

  final user = FirebaseAuth.instance.currentUser;
  if (_shows(BuyerDashboardScreen) &&
      sameEmail(user?.email, values.expectedEmail)) {
    _result('signed-in');
    return;
  }
  final note = user == null
      ? 'sign-in did not complete'
      : !_shows(BuyerDashboardScreen)
          ? 'signed in, but the dashboard did not appear'
          : 'signed in, but not as the expected account';
  _result('failed', note);
  fail(note);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI tester sign-in', (tester) async {
    try {
      await _signIn(tester);
    } catch (_) {
      // Start-up or a finder threw before a result was printed; the tool
      // needs a result line in every case.
      if (!_printed) _result('failed', 'the test stopped with an error');
      rethrow;
    }
  });
}
