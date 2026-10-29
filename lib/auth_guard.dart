import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Signed-out visitors can browse pets (App Review 5.1.1); actions that need an
/// account call [requireSignIn] first.
///
/// Returns true when a user is signed in. Otherwise shows a snackbar whose
/// "Sign in" action opens the login screen, and returns false.
bool requireSignIn(BuildContext context, {String message = 'Please sign in to continue.'}) {
  if (FirebaseAuth.instance.currentUser != null) return true;
  showSignInPrompt(context, message: message);
  return false;
}

/// Shows the "sign in to continue" snackbar. The login screen replaces the
/// whole stack and lands on the dashboard after sign-in.
void showSignInPrompt(BuildContext context, {String message = 'Please sign in to continue.'}) {
  final navigator = Navigator.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Sign in',
          textColor: signInActionColor(Theme.of(context)),
          onPressed: () => navigator.pushNamedAndRemoveUntil('/login', (route) => false),
        ),
      ),
    );
}

/// The light theme's swatch-based scheme leaves the action's default colour
/// (inversePrimary → onPrimary) black on the black snackbar, so pick a colour
/// that contrasts with the snackbar background in either theme.
Color signInActionColor(ThemeData theme) {
  final background = theme.snackBarTheme.backgroundColor ?? theme.colorScheme.inverseSurface;
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.purple.shade100
      : Colors.purple.shade700;
}
