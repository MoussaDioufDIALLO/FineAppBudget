import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Connexion Google pour Windows / macOS / Linux (flux OAuth « application de
/// bureau » avec PKCE et redirection locale 127.0.0.1), puis échange vers Firebase.
///
/// Identifiants à fournir au lancement :
///   --dart-define=GOOGLE_DESKTOP_CLIENT_ID=...
///   --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=...
class DesktopGoogleAuth {
  static const clientId = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');
  static const clientSecret = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET');
  static bool get configured => clientId.isNotEmpty && clientSecret.isNotEmpty;

  static String _random(int n) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final r = Random.secure();
    return List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static Future<OAuthCredential> signIn() async {
    if (!configured) {
      throw Exception('Connexion Google non configurée sur ce poste (voir README).');
    }
    final verifier = _random(64);
    final challenge = base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');
    final state = _random(24);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirect = 'http://127.0.0.1:${server.port}';
    try {
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'state': state,
      });
      if (!await launchUrl(authUri, mode: LaunchMode.externalApplication)) {
        throw Exception('Impossible d\'ouvrir le navigateur.');
      }

      final req = await server.first.timeout(const Duration(minutes: 3));
      final q = req.uri.queryParameters;
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('<html><head><meta charset="utf-8"></head><body style="font-family:sans-serif;'
            'text-align:center;margin-top:20vh"><h2>FinWise</h2>'
            '<p>Connexion terminée. Vous pouvez fermer cet onglet.</p></body></html>');
      await req.response.close();

      if (q['error'] != null) throw Exception('Google : ${q['error']}');
      if (q['state'] != state || q['code'] == null) {
        throw Exception('Réponse de connexion invalide.');
      }

      final res = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        body: {
          'code': q['code']!,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': redirect,
          'grant_type': 'authorization_code',
          'code_verifier': verifier,
        },
      );
      if (res.statusCode != 200) {
        throw Exception('Échec de la connexion Google (${res.statusCode}).');
      }
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return GoogleAuthProvider.credential(
        idToken: j['id_token'] as String?,
        accessToken: j['access_token'] as String?,
      );
    } on TimeoutException {
      throw Exception('Connexion Google expirée. Réessayez.');
    } finally {
      await server.close(force: true);
    }
  }
}
