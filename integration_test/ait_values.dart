import 'dart:convert';
import 'dart:io';

/// The test account the AI tester's `refresh-sessions mobile` tool hands to
/// `sign_in_test.dart`. Never print, log or screenshot these values.
class AitValues {
  const AitValues({
    required this.email,
    required this.password,
    required this.expectedEmail,
  });

  final String email;
  final String password;
  final String expectedEmail;
}

/// Reads the values file the tool pushed to the emulator and deletes it
/// straight away, also when it cannot be read. Returns null when [path] is
/// empty, the file is missing or unreadable, or it lacks one of AIT_EMAIL,
/// AIT_PASSWORD and AIT_EXPECTED_EMAIL.
AitValues? takeAitValues(String path) {
  if (path.isEmpty) return null;
  final file = File(path);
  try {
    if (!file.existsSync()) return null;
    final data = jsonDecode(file.readAsStringSync());
    if (data is! Map) return null;
    final email = data['AIT_EMAIL'];
    final password = data['AIT_PASSWORD'];
    final expected = data['AIT_EXPECTED_EMAIL'];
    if (email is! String || password is! String || expected is! String) {
      return null;
    }
    if (email.isEmpty || password.isEmpty || expected.isEmpty) return null;
    return AitValues(email: email, password: password, expectedEmail: expected);
  } on FormatException {
    return null;
  } on FileSystemException {
    return null;
  } finally {
    try {
      if (file.existsSync()) file.deleteSync();
    } on FileSystemException {
      // The tool deletes its copy on the device in its own clean-up as well.
    }
  }
}

/// Whether two account emails are the same address (Firebase lower-cases
/// emails, the test-accounts file may not).
bool sameEmail(String? a, String b) =>
    a != null && a.trim().toLowerCase() == b.trim().toLowerCase();
