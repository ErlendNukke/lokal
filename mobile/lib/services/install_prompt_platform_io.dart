/// Non-web platforms: install prompt is not applicable.
class InstallPromptPlatform {
  static bool get supported => false;

  static bool get runningInstalled => false;

  static bool get showIosShareHint => false;

  static bool get chromiumInstallReady => false;

  static void listenForInstallPrompt(void Function() onAvailable) {}

  static Future<bool> triggerChromiumInstall() async => false;
}
