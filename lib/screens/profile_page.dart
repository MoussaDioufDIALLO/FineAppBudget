import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';
import 'account_pages.dart';
import 'ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final photo = auth.user?.photoURL;
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profil',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.green, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.grey,
                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                    child: photo == null
                        ? const Icon(Icons.person, size: 46, color: AppColors.ink)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(auth.displayName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(auth.email ?? 'Mode local',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ]),
            ),
          ),
          Container(
            color: AppColors.grey,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(children: [
              _MenuTile(Icons.person_outline, 'Modifier le profil',
                  () => _open(context, const EditProfilePage())),
              _MenuTile(Icons.shield_outlined, 'Sécurité',
                  () => _open(context, const SecurityPage())),
              _MenuTile(Icons.settings_outlined, 'Réglages',
                  () => _open(context, const SettingsPage())),
              _MenuTile(Icons.support_agent, 'Aide', () => _open(context, const HelpPage())),
              _MenuTile(Icons.logout, 'Déconnexion', () async {
                final ok = await confirmDialog(
                  context,
                  icon: Icons.logout,
                  title: 'Te déconnecter de FinWise ?',
                  message: 'Tes données restent en sécurité. Tu pourras te reconnecter à tout moment.',
                  yes: 'Oui',
                  no: 'Pas maintenant',
                );
                if (ok && context.mounted) await context.read<AuthService>().signOut();
              }, danger: true),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(this.icon, this.label, this.onTap, {this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? AppColors.danger : AppColors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: c.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: danger ? AppColors.danger : AppColors.ink)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}
