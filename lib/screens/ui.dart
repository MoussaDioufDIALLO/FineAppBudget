import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Page type : fond blanc, titre à gauche, bouton retour rond.
class FwScaffold extends StatelessWidget {
  const FwScaffold({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              if (canPop)
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.grey, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.arrow_back, size: 20, color: AppColors.ink),
                  ),
                )
              else
                const SizedBox(width: 8),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              if (trailing != null) trailing!,
            ]),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520), child: child),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Fenêtre de confirmation : icône, texte, bouton clair "oui" et noir "non".
Future<bool> confirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String yes = 'Oui',
  String no = 'Pas maintenant',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.grey, foregroundColor: AppColors.ink),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(yes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(no),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
  return r ?? false;
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _hide,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _hide = !_hide),
        ),
      ),
    );
  }
}

/// Exécute une action d'authentification et renvoie un message d'erreur (ou null).
Future<String?> guard(Future<void> Function() f) async {
  try {
    await f();
    return null;
  } on FirebaseAuthException catch (e) {
    return frenchAuthError(e);
  } catch (e) {
    return e.toString();
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message!, style: const TextStyle(color: Colors.red)),
        );
}

void toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// Messages d'erreur Firebase en français.
String frenchAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return "Adresse e-mail invalide.";
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return "E-mail ou mot de passe incorrect.";
    case 'email-already-in-use':
      return "Un compte existe déjà avec cet e-mail.";
    case 'weak-password':
      return "Mot de passe trop faible (6 caractères minimum).";
    case 'user-disabled':
      return "Ce compte a été désactivé.";
    case 'too-many-requests':
      return "Trop de tentatives. Réessaie dans quelques minutes.";
    case 'network-request-failed':
      return "Pas de connexion internet.";
    case 'requires-recent-login':
      return "Reconnecte-toi puis réessaie.";
    case 'operation-not-allowed':
      return "Cette méthode de connexion n'est pas activée dans Firebase.";
    default:
      return e.message ?? e.code;
  }
}
