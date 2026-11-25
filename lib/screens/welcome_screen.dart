import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/icon/logo.png', height: 110),
                const SizedBox(height: 4),
                const Text('FinWise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 44, fontWeight: FontWeight.w700, color: AppColors.green)),
                const SizedBox(height: 8),
                const Text('Suivez vos revenus et dépenses, partout.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 40),
                if (auth.cloudReady) ...[
                  FilledButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Se connecter'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDFF7E2)),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen())),
                    child: const Text('Créer un compte'),
                  ),
                ] else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Cloud non configuré (voir README : flutterfire configure). '
                          'L\'app fonctionne en mode local.'),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: auth.continueOffline,
                  child: const Text('Continuer sans compte (local)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
