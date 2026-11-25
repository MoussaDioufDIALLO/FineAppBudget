import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_lock.dart';
import '../auth_service.dart';
import '../theme.dart';
import '../txn_store.dart';
import 'ui.dart';

// ---------------------------------------------------------------- Edit profile
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = context.read<AuthService>();
    _name = TextEditingController(text: a.displayName);
    _phone = TextEditingController(text: a.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final a = context.read<AuthService>();
    final err = await guard(() => a.updateProfile(_name.text, _phone.text));
    if (!mounted) return;
    if (err == null) {
      toast(context, 'Profil mis à jour.');
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
    final email = context.read<AuthService>().email;
    return FwScaffold(
      title: 'Modifier le profil',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Paramètres du compte',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(
              controller: _name, decoration: const InputDecoration(labelText: 'Nom d\'utilisateur')),
          const SizedBox(height: 12),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone')),
          if (email != null) ...[
            const SizedBox(height: 12),
            TextField(
                enabled: false,
                controller: TextEditingController(text: email),
                decoration: const InputDecoration(labelText: 'Email')),
          ],
          ErrorText(_error),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Enregistrer')),
        ]),
      ),
    );
  }
}

// -------------------------------------------------------------------- Sécurité
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLock>();
    return FwScaffold(
      title: 'Sécurité',
      child: ListView(padding: const EdgeInsets.all(20), children: [
        SwitchListTile(
          title: const Text('Verrouillage biométrique',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text(
              'Empreinte, Face ID ou Windows Hello. Le code de l\'appareil sert de secours.'),
          value: lock.enabled,
          onChanged: (v) async {
            final ok = await lock.setEnabled(v);
            if (!ok && context.mounted) {
              toast(context, 'Biométrie indisponible ou authentification refusée.');
            }
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Conditions d\'utilisation',
              style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TermsPage())),
        ),
      ]),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FwScaffold(
      title: 'Conditions',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(28),
        child: Text(
          'Texte provisoire : à remplacer par vos conditions d\'utilisation et votre '
          'politique de confidentialité avant publication.\n\n'
          '• Vos transactions sont enregistrées sur votre appareil, et dans votre espace '
          'cloud privé si vous êtes connecté.\n'
          '• Vous pouvez supprimer votre compte et vos données à tout moment depuis '
          'Réglages > Supprimer le compte.',
          style: TextStyle(height: 1.5),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------- Réglages
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    void open(Widget p) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => p));
    return FwScaffold(
      title: 'Réglages',
      child: ListView(padding: const EdgeInsets.all(20), children: [
        _Row(Icons.cloud_outlined, 'Compte & cloud', () => open(const CloudPage())),
        if (auth.hasPassword)
          _Row(Icons.key, 'Mot de passe', () => open(const PasswordPage())),
        _Row(Icons.person_off_outlined, 'Supprimer le compte',
            () => open(const DeleteAccountPage())),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
            backgroundColor: AppColors.green, child: Icon(icon, color: AppColors.dark)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class CloudPage extends StatelessWidget {
  const CloudPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final store = context.watch<TxnStore>();
    final String status;
    if (!auth.cloudReady) {
      status = 'Cloud non configuré. Lancez « flutterfire configure » (voir README).';
    } else if (auth.user != null) {
      status = 'Connecté : ${auth.email}\nVos transactions, votre budget et votre profil sont '
          'sauvegardés dans le cloud : connectez-vous avec ce compte sur un autre appareil '
          'pour tout retrouver.';
    } else {
      status = 'Mode local : les données restent sur cet appareil.';
    }
    return FwScaffold(
      title: 'Compte & cloud',
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(status, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          if (auth.user != null && store.localCount > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('${store.localCount} transaction(s) créées en mode local ne sont '
                    'pas encore dans votre compte.'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final err = await guard(() async {
                  final n = await store.importLocal();
                  if (context.mounted) toast(context, '$n transaction(s) importée(s).');
                });
                if (err != null && context.mounted) toast(context, err);
              },
              child: const Text('Importer mes données locales'),
            ),
          ],
          if (auth.cloudReady && auth.user == null)
            FilledButton(
              onPressed: () async {
                Navigator.of(context).popUntil((r) => r.isFirst);
                await auth.signOut(); // retour à l'écran de connexion
              },
              child: const Text('Me connecter / lier mon compte'),
            ),
        ]),
      ),
    );
  }
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _new2.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 6) {
      setState(() => _error = '6 caractères minimum.');
      return;
    }
    if (_new.text != _new2.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final a = context.read<AuthService>();
    final err = await guard(() => a.changePassword(_cur.text, _new.text));
    if (!mounted) return;
    if (err == null) {
      toast(context, 'Mot de passe modifié.');
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
      title: 'Mot de passe',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PasswordField(controller: _cur, label: 'Mot de passe actuel'),
          const SizedBox(height: 12),
          PasswordField(controller: _new, label: 'Nouveau mot de passe'),
          const SizedBox(height: 12),
          PasswordField(controller: _new2, label: 'Confirmer le nouveau mot de passe'),
          ErrorText(_error),
          const SizedBox(height: 24),
          FilledButton(onPressed: _busy ? null : _save, child: const Text('Modifier')),
        ]),
      ),
    );
  }
}

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final store = context.read<TxnStore>();
    final err = await guard(
        () => auth.deleteAccount(_pass.text, beforeDelete: store.clearAll));
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
    final auth = context.watch<AuthService>();
    return FwScaffold(
      title: 'Supprimer le compte',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Voulez-vous vraiment supprimer votre compte ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFDFF7E2), borderRadius: BorderRadius.circular(20)),
            child: const Text(
                'Toutes vos données seront supprimées définitivement :\n\n'
                '• vos revenus, dépenses et transactions\n'
                '• l\'accès à votre compte\n\n'
                'Cette action est irréversible.'),
          ),
          if (auth.hasPassword) ...[
            const SizedBox(height: 20),
            const Text('Entrez votre mot de passe pour confirmer :'),
            const SizedBox(height: 8),
            PasswordField(controller: _pass, label: 'Mot de passe'),
          ],
          ErrorText(_error),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5575B), foregroundColor: Colors.white),
            onPressed: _busy ? null : _delete,
            child: const Text('Oui, supprimer mon compte'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------------ Aide
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _faq = [
    ('Comment utiliser FinWise ?',
        'Ajoutez vos revenus et dépenses avec le bouton +. L\'accueil affiche votre solde, votre budget du mois et vos dernières transactions.'),
    ('Comment fonctionne le budget ?',
        'Touchez la barre de budget sur l\'accueil pour fixer votre budget mensuel. Elle se remplit avec vos dépenses du mois.'),
    ('Comment synchroniser mes appareils ?',
        'Connectez-vous avec le même compte sur le téléphone et sur l\'ordinateur : vos transactions sont stockées dans votre espace cloud.'),
    ('Puis-je utiliser l\'app hors ligne ?',
        'Oui. En mode local, les données restent sur l\'appareil. Connecté, les modifications faites hors ligne sont envoyées au retour du réseau.'),
    ('Comment activer l\'empreinte / Face ID ?',
        'Profil > Sécurité > Verrouillage biométrique.'),
    ('J\'ai oublié mon mot de passe',
        'Sur l\'écran de connexion, touchez « Mot de passe oublié » : un lien de réinitialisation est envoyé par email.'),
    ('Comment supprimer mon compte ?',
        'Profil > Réglages > Supprimer le compte. L\'action est définitive.'),
  ];

  @override
  Widget build(BuildContext context) {
    return FwScaffold(
      title: 'Aide & FAQ',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        for (final q in _faq)
          ExpansionTile(
            title: Text(q.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(q.$2)],
          ),
      ]),
    );
  }
}
