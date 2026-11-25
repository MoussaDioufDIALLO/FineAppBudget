import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';
import 'account_pages.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final photo = auth.user?.photoURL;
    return ListView(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(48)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              const Text('Profil',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.mint,
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? const Icon(Icons.person, size: 48, color: AppColors.dark)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(auth.displayName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
              Text(auth.email ?? 'Mode local',
                  style: const TextStyle(color: AppColors.dark)),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _MenuTile(Icons.person_outline, 'Modifier le profil',
            () => _open(context, const EditProfilePage())),
        _MenuTile(Icons.shield_outlined, 'Sécurité', () => _open(context, const SecurityPage())),
        _MenuTile(Icons.settings_outlined, 'Réglages', () => _open(context, const SettingsPage())),
        _MenuTile(Icons.support_agent, 'Aide', () => _open(context, const HelpPage())),
        _MenuTile(Icons.logout, 'Déconnexion', () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Terminer la session ?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Oui, me déconnecter')),
              ],
            ),
          );
          if (ok == true && context.mounted) await context.read<AuthService>().signOut();
        }),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
