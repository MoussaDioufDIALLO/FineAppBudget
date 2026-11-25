import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import 'forgot_screen.dart';
import 'signup_screen.dart';
import 'ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await guard(action);
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
    final auth = context.read<AuthService>();
    return FwScaffold(
      title: 'Bienvenue',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 14),
          PasswordField(controller: _pass, label: 'Mot de passe'),
          ErrorText(_error),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ForgotScreen())),
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() => auth.signInWithEmail(_email.text, _pass.text)),
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('ou')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (_busy || !auth.googleSupported) ? null : () => _run(auth.signInWithGoogle),
            icon: const Icon(Icons.g_mobiledata, size: 32),
            label: Text(auth.googleSupported
                ? 'Continuer avec Google'
                : 'Google indisponible (voir README)'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
            child: const Text('Pas de compte ? Créer un compte'),
          ),
        ]),
      ),
    );
  }
}
