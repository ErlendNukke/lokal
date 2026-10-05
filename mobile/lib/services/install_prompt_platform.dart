import 'install_prompt_platform_io.dart'
    if (dart.library.html) 'install_prompt_platform_web.dart' as impl;

/// Platform bridge for add-to-home-screen (web only).
class InstallPromptPlatform {
  static bool get supported => impl.InstallPromptPlatform.supported;

  static bool get runningInstalled => impl.InstallPromptPlatform.runningInstalled;

  static bool get showIosShareHint => impl.InstallPromptPlatform.showIosShareHint;

  static bool get chromiumInstallReady => impl.InstallPromptPlatform.chromiumInstallReady;

  static void listenForInstallPrompt(void Function() onAvailable) =>
      impl.InstallPromptPlatform.listenForInstallPrompt(onAvailable);

  static Future<bool> triggerChromiumInstall() =>
      impl.InstallPromptPlatform.triggerChromiumInstall();
}
