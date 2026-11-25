import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import 'ui.dart';

class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final err = await guard(() => auth.sendPasswordReset(_email.text));
    if (!mounted) return;
    if (err == null) {
      toast(context, 'Email envoyé : suivez le lien pour choisir un nouveau mot de passe.');
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FwScaffold(
      title: 'Mot de passe oublié',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Réinitialiser le mot de passe ?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Entrez votre email : nous vous envoyons un lien de réinitialisation.'),
          const SizedBox(height: 20),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse email')),
          ErrorText(_error),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _busy ? null : _send, child: const Text('Envoyer le lien')),
        ]),
      ),
    );
  }
}
