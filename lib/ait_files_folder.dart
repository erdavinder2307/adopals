import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Debug and profile builds on Android ask once for the app's external files
/// folder (`Android/data/<package>/files`), because Android only creates it
/// when the app asks. The AI tester's `refresh-sessions mobile` tool pushes
/// the values file for `integration_test/sign_in_test.dart` into that folder
/// and needs it to exist with the app as owner. Release builds do nothing.
Future<void> ensureAitFilesFolder({
  bool? isAndroid,
  bool isRelease = kReleaseMode,
  Future<Directory?> Function() getFolder = getExternalStorageDirectory,
}) async {
  if (isRelease || kIsWeb || !(isAndroid ?? Platform.isAndroid)) return;
  try {
    await getFolder();
  } catch (error) {
    debugPrint('External files folder not available: $error');
  }
}
