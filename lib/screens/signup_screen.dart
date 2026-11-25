import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import 'login_screen.dart';
import 'ui.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Nom et email requis.');
      return;
    }
    if (_pass.text.length < 6) {
      setState(() => _error = 'Mot de passe : 6 caractères minimum.');
      return;
    }
    if (_pass.text != _pass2.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final err = await guard(() =>
        auth.registerWithEmail(_email.text, _pass.text, _name.text, _phone.text));
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).popUntil((r) => r.isFirst);
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
      title: 'Créer un compte',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet')),
          const SizedBox(height: 12),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone (optionnel)')),
          const SizedBox(height: 12),
          PasswordField(controller: _pass, label: 'Mot de passe'),
          const SizedBox(height: 12),
          PasswordField(controller: _pass2, label: 'Confirmer le mot de passe'),
          ErrorText(_error),
          const SizedBox(height: 20),
          FilledButton(
              onPressed: _busy ? null : _submit, child: const Text('Créer mon compte')),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Déjà un compte ? Se connecter'),
          ),
        ]),
      ),
    );
  }
}
