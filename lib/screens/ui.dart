import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Page type du prototype : bandeau vert + carte arrondie claire.
class FwScaffold extends StatelessWidget {
  const FwScaffold({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.green,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          SizedBox(
            height: 72,
            child: Row(children: [
              SizedBox(
                width: 56,
                child: canPop
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context))
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
                ),
              ),
              SizedBox(width: 56, child: trailing),
            ]),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
              ),
              child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520), child: child),
              ),
            ),
          ),
        ]),
      ),
    );
  }
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
