import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'desktop_google_auth.dart';

class AuthService extends ChangeNotifier {
  AuthService(this.cloudReady, this._prefs) {
    offline = _prefs.getBool('offline') ?? false;
    if (cloudReady) {
      user = FirebaseAuth.instance.currentUser;
      if (user != null) _pull();
      _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
        user = u;
        if (u != null) _pull();
        notifyListeners();
      });
    }
  }

  final bool cloudReady;
  final SharedPreferences _prefs;
  StreamSubscription<User?>? _sub;
  User? user;
  bool offline = false;

  DocumentReference<Map<String, dynamic>>? get _doc => user == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(user!.uid);

  /// Récupère le profil sauvegardé dans le cloud (nouvel appareil).
  Future<void> _pull() async {
    try {
      final m = (await _doc?.get())?.data();
      if (m == null) return;
      if (m['phone'] is String) await _prefs.setString('phone', m['phone'] as String);
      notifyListeners();
    } catch (e) {
      debugPrint('Profil cloud indisponible : $e');
    }
  }

  /// Sauvegarde le profil dans le cloud (sans attendre le réseau).
  void _push() {
    _doc
        ?.set({
          'name': displayName,
          'phone': phone,
          'email': user?.email,
        }, SetOptions(merge: true))
        .catchError((Object e) => debugPrint('Sauvegarde profil : $e'));
  }

  bool get signedIn => user != null || offline;
  String get displayName =>
      user?.displayName ??
      _prefs.getString('name') ??
      user?.email?.split('@').first ??
      'Utilisateur';
  String? get email => user?.email;
  String get phone => _prefs.getString('phone') ?? '';
  bool get hasPassword =>
      user?.providerData.any((p) => p.providerId == 'password') ?? false;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Mobile : plugin google_sign_in. Bureau : flux OAuth maison (si configuré).
  bool get googleSupported => _isMobile || (_isDesktop && DesktopGoogleAuth.configured);

  Future<void> signInWithGoogle() async {
    if (_isDesktop) {
      await FirebaseAuth.instance.signInWithCredential(await DesktopGoogleAuth.signIn());
      return;
    }
    final g = await GoogleSignIn().signIn();
    if (g == null) return; // annulé
    final a = await g.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: a.accessToken,
      idToken: a.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(cred);
  }

  Future<void> signInWithEmail(String email, String password) =>
      FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> registerWithEmail(
      String email, String password, String name, String phone) async {
    final c = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email.trim(), password: password);
    await _prefs.setString('phone', phone.trim());
    if (name.trim().isNotEmpty) {
      await c.user?.updateDisplayName(name.trim());
      await c.user?.reload();
      user = FirebaseAuth.instance.currentUser;
      notifyListeners();
    }
    _push();
  }

  Future<void> sendPasswordReset(String email) =>
      FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

  Future<void> updateProfile(String name, String phone) async {
    await _prefs.setString('phone', phone.trim());
    await _prefs.setString('name', name.trim());
    if (user != null) {
      await user!.updateDisplayName(name.trim());
      await user!.reload();
      user = FirebaseAuth.instance.currentUser;
    }
    _push();
    notifyListeners();
  }

  Future<void> _reauth(String password) async {
    final u = user!;
    await u.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: u.email!, password: password));
  }

  Future<void> changePassword(String current, String next) async {
    await _reauth(current);
    await user!.updatePassword(next);
  }

  Future<void> _reauthGoogle() async {
    if (_isDesktop) {
      await user!.reauthenticateWithCredential(await DesktopGoogleAuth.signIn());
      return;
    }
    final g = await GoogleSignIn().signIn();
    if (g == null) throw Exception('Réauthentification annulée');
    final a = await g.authentication;
    await user!.reauthenticateWithCredential(GoogleAuthProvider.credential(
        accessToken: a.accessToken, idToken: a.idToken));
  }

  /// Supprime le compte. [beforeDelete] efface les données (après réauthentification).
  Future<void> deleteAccount(String? password,
      {Future<void> Function()? beforeDelete}) async {
    if (user != null) {
      if (hasPassword) {
        await _reauth(password ?? '');
      } else if (googleSupported) {
        await _reauthGoogle();
      }
    }
    await beforeDelete?.call();
    if (user != null) await user!.delete();
    await _prefs.remove('name');
    await _prefs.remove('phone');
    await signOut();
  }

  Future<void> continueOffline() async {
    offline = true;
    await _prefs.setBool('offline', true);
    notifyListeners();
  }

  Future<void> signOut() async {
    offline = false;
    await _prefs.remove('offline');
    if (cloudReady && user != null) {
      if (_isMobile) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
