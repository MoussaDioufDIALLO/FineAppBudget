import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verrouillage biométrique (empreinte / Face ID / Windows Hello).
/// Le code PIN de l'appareil sert de secours (biometricOnly: false).
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  AppLock(this._prefs) {
    enabled = _prefs.getBool('bio') ?? false;
    locked = enabled;
    WidgetsBinding.instance.addObserver(this);
  }

  final SharedPreferences _prefs;
  final LocalAuthentication _auth = LocalAuthentication();
  bool enabled = false;
  bool locked = false;
  bool _busy = false;

  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _prompt() async {
    _busy = true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Déverrouillez FinWise',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (e) {
      debugPrint('Biométrie : $e');
      return false;
    } finally {
      // Les événements de cycle de vie arrivent parfois après la fermeture de la boîte.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      _busy = false;
    }
  }

  Future<bool> setEnabled(bool value) async {
    if (value) {
      if (!await isAvailable()) return false;
      if (!await _prompt()) return false;
    }
    enabled = value;
    await _prefs.setBool('bio', value);
    notifyListeners();
    return true;
  }

  Future<void> unlock() async {
    if (await _prompt()) {
      locked = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!enabled || _busy || locked) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      locked = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
