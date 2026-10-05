import 'dart:js_interop';

import 'package:web/web.dart';

@JS('window.__lokalDeferredInstall')
external JSObject? get _deferredInstallGlobal;

@JS('window.__lokalDeferredInstall')
external set _deferredInstallGlobal(JSObject? value);

extension type _BeforeInstallPromptEvent(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
}

/// Web-only detection and Chromium install prompt bridge (see index.html).
class InstallPromptPlatform {
  static bool get supported => true;

  static bool get runningInstalled =>
      window.matchMedia('(display-mode: standalone)').matches;

  static bool get showIosShareHint {
    if (runningInstalled) return false;
    final ua = window.navigator.userAgent;
    return ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
  }

  static bool get chromiumInstallReady => _deferredInstallGlobal != null;

  static void listenForInstallPrompt(void Function() onAvailable) {
    window.addEventListener(
      'lokal-install-available',
      ((Event _) => onAvailable()).toJS,
    );
    if (_deferredInstallGlobal != null) {
      onAvailable();
    }
  }

  static Future<bool> triggerChromiumInstall() async {
    final event = _deferredInstallGlobal;
    if (event == null) return false;
    await _BeforeInstallPromptEvent(event).prompt().toDart;
    _deferredInstallGlobal = null;
    return true;
  }
}
