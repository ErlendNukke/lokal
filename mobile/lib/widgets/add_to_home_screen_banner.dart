import 'package:flutter/material.dart';
import 'package:lokal/services/install_prompt_controller.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// Unobtrusive add-to-home-screen hint for mobile web (Chromium + iOS Safari).
class AddToHomeScreenBanner extends StatelessWidget {
  const AddToHomeScreenBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final prompt = context.watch<InstallPromptController>();
    if (!prompt.visible) {
      return const SizedBox.shrink();
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Semantics(
      container: true,
      label: prompt.showIosHint
          ? 'Lisa Lokal avaekraanile: kasuta Jagamise menüüd'
          : 'Lisa Lokal avaekraanile',
      child: Material(
        elevation: 6,
        color: LokalColors.forestDark,
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(16, 12, 12, 12 + bottomInset),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.install_mobile, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lisa Lokal avaekraanile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt.showIosHint
                          ? 'Puuduta Safari menüüs Jagamise ikooni ja vali „Lisa avaekraanile“.'
                          : 'Kiire ligipääs kaardile ja tellimustele otse avaekraanilt.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (prompt.showChromiumInstall) ...[
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => prompt.install(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: LokalColors.forestDark,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Lisa'),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => prompt.dismiss(),
                tooltip: 'Peida meeldetuletus',
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
