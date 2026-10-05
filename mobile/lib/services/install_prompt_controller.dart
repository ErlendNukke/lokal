import 'package:flutter/foundation.dart';
import 'package:lokal/services/install_prompt_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decides when to show the add-to-home-screen banner on web.
class InstallPromptController extends ChangeNotifier {
  InstallPromptController() {
    _init();
  }

  static const _prefsDismissedUntil = 'a2hs_dismissed_until_ms';
  static const _prefsVisitCount = 'a2hs_visit_count';
  static const _prefsProductViewed = 'a2hs_product_viewed';
  static const _dismissDays = 30;

  static const _disabled = bool.fromEnvironment('DISABLE_INSTALL_PROMPT', defaultValue: false);
  static const _forceShow = bool.fromEnvironment('FORCE_INSTALL_PROMPT', defaultValue: false);

  bool _visible = false;
  bool _chromiumReady = false;
  int _visitCount = 0;
  bool _productViewed = false;
  bool _dismissed = false;
  bool _initialized = false;

  bool get visible => _visible;

  bool get showChromiumInstall =>
      _visible && _chromiumReady && !InstallPromptPlatform.showIosShareHint;

  bool get showIosHint => _visible && InstallPromptPlatform.showIosShareHint;

  Future<void> _init() async {
    if (!kIsWeb || _disabled || !InstallPromptPlatform.supported) {
      _initialized = true;
      return;
    }
    if (InstallPromptPlatform.runningInstalled) {
      _initialized = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissedUntil = prefs.getInt(_prefsDismissedUntil) ?? 0;
    if (dismissedUntil > DateTime.now().millisecondsSinceEpoch) {
      _dismissed = true;
    }

    _visitCount = prefs.getInt(_prefsVisitCount) ?? 0;
    _visitCount += 1;
    await prefs.setInt(_prefsVisitCount, _visitCount);

    _productViewed = prefs.getBool(_prefsProductViewed) ?? false;

    InstallPromptPlatform.listenForInstallPrompt(() {
      _chromiumReady = InstallPromptPlatform.chromiumInstallReady;
      _reevaluate();
    });
    _chromiumReady = InstallPromptPlatform.chromiumInstallReady;

    _initialized = true;
    _reevaluate();
  }

  Future<void> recordProductViewed() async {
    if (!kIsWeb || _disabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsProductViewed, true);
    _productViewed = true;
    _reevaluate();
  }

  Future<void> dismiss() async {
    final until = DateTime.now().add(const Duration(days: _dismissDays)).millisecondsSinceEpoch;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsDismissedUntil, until);
    _dismissed = true;
    _visible = false;
    notifyListeners();
  }

  Future<void> install() async {
    final accepted = await InstallPromptPlatform.triggerChromiumInstall();
    if (accepted) {
      _visible = false;
      notifyListeners();
    }
  }

  void _reevaluate() {
    if (!_initialized) return;
    if (_dismissed || InstallPromptPlatform.runningInstalled) {
      _visible = false;
      notifyListeners();
      return;
    }

    if (_forceShow) {
      _visible = true;
      notifyListeners();
      return;
    }

    final engaged = _visitCount >= 2 || _productViewed;
    if (!engaged) {
      _visible = false;
      notifyListeners();
      return;
    }

    if (InstallPromptPlatform.showIosShareHint) {
      _visible = true;
      notifyListeners();
      return;
    }

    if (_chromiumReady) {
      _visible = true;
      notifyListeners();
      return;
    }

    _visible = false;
    notifyListeners();
  }
}
