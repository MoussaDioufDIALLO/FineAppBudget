import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Écran de démarrage inspiré de Trackfinz.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('FinWise',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 28),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12), shape: BoxShape.circle),
                    padding: const EdgeInsets.all(36),
                    child: Image.asset('assets/icon/logo.png'),
                  ),
                  const SizedBox(height: 28),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Ton assistant\n'),
                      TextSpan(
                          text: 'financier',
                          style: TextStyle(
                              color: AppColors.green,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.green)),
                      TextSpan(text: ' personnel'),
                    ]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  const Text('Suis tes revenus et dépenses, partout.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => auth.cloudReady
                        ? Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()))
                        : auth.continueOffline(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        boxShadow: softShadow(0.2),
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (auth.cloudReady) ...[
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen())),
                      child: const Text('Créer un compte'),
                    ),
                    TextButton(
                      onPressed: auth.continueOffline,
                      child: const Text('Continuer sans compte (local)',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Cloud non configuré : l\'app fonctionne en mode local.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
