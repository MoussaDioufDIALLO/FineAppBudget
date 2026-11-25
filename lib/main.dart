import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock.dart';
import 'auth_service.dart';
import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme.dart';
import 'txn_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  var cloudReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    cloudReady = true;
  } catch (e) {
    debugPrint('Firebase non configuré (mode local uniquement) : $e');
  }
  final ready = cloudReady;
  final prefs = await SharedPreferences.getInstance();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthService(ready, prefs)),
      ChangeNotifierProvider(create: (_) => AppLock(prefs)),
      ChangeNotifierProxyProvider<AuthService, TxnStore>(
        create: (_) => TxnStore(prefs),
        update: (_, auth, store) {
          store!.bind(auth);
          return store;
        },
      ),
    ],
    child: const FinWiseApp(),
  ));
}

class FinWiseApp extends StatelessWidget {
  const FinWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinWise',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('fr'), Locale('en')],
      home: const AppGate(),
    );
  }
}

/// Connexion -> verrou biométrique -> application.
class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final lock = context.watch<AppLock>();
    if (!auth.signedIn) return const WelcomeScreen();
    if (lock.locked) return const LockScreen();
    return const HomeShell();
  }
}
