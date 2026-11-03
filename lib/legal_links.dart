import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const String privacyPolicyUrl = 'https://adopals.com/privacy-policy';
const String termsUrl = 'https://adopals.com/terms-and-conditions';

Future<void> openLegalLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  bool opened = false;
  try {
    opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Could not open $url: $e');
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not open the page. Please visit $url')),
    );
  }
}
