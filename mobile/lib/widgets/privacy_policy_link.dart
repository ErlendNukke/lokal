import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the published privacy policy (mobile/web/privacy/index.html).
class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  static Uri get url => kIsWeb
      ? Uri.base.resolve('/privacy/')
      : Uri.parse('https://lokal-eu.web.app/privacy/');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => launchUrl(url),
        child: const Text('Privaatsuspoliitika'),
      ),
    );
  }
}
