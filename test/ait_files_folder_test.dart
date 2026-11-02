import 'dart:io';

import 'package:adopals/ait_files_folder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int calls;
  Future<Directory?> fakeFolder() async {
    calls++;
    return null;
  }

  setUp(() => calls = 0);

  test('debug Android build asks for the external files folder', () async {
    await ensureAitFilesFolder(
        isAndroid: true, isRelease: false, getFolder: fakeFolder);
    expect(calls, 1);
  });

  test('release build does not ask', () async {
    await ensureAitFilesFolder(
        isAndroid: true, isRelease: true, getFolder: fakeFolder);
    expect(calls, 0);
  });

  test('iOS does not ask', () async {
    await ensureAitFilesFolder(
        isAndroid: false, isRelease: false, getFolder: fakeFolder);
    expect(calls, 0);
  });

  test('an error from the platform does not stop the app', () async {
    await ensureAitFilesFolder(
      isAndroid: true,
      isRelease: false,
      getFolder: () async => throw const FileSystemException('no storage'),
    );
  });
}
