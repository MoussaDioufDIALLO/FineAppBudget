import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';
import '../txn_store.dart';
import 'notifications_page.dart';
import 'widgets.dart';

/// Accueil inspiré de Trackfinz : salutation, boutons Dépense / Revenu,
/// carte de solde avec masquage, puis rapports et transactions.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _hide = false;

  Future<void> _editBudget(BuildContext context, TxnStore store) async {
    final c = TextEditingController(text: store.budget.round().toString());
    final v = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Budget mensuel (FCFA)'),
        content: TextField(controller: c, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, double.tryParse(c.text.trim())),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (v != null && v > 0) await store.setBudget(v);
  }

  Widget _actionButton(String label, IconData icon, Color bg, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TxnStore>();
    final auth = context.watch<AuthService>();
    final list = store.filtered;
    final used = store.budgetUsed;
    final balance = _hide ? '••••••' : money.format(store.balance);

    return Container(
      color: Colors.white,
      child: Column(children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      const TextSpan(text: 'Bonjour '),
                      TextSpan(
                          text: auth.displayName,
                          style: const TextStyle(color: AppColors.green)),
                      const TextSpan(text: ' 👋'),
                    ]),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(auth.user != null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                          size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                          auth.user != null
                              ? 'Prêt à suivre ton argent, synchronisé'
                              : 'Prêt à suivre ton argent (mode local)',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  ]),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppColors.ink),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationsPage())),
                ),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                _actionButton('Dépense', Icons.north_east, AppColors.ink,
                    () => showAddTransaction(context, expense: true)),
                const SizedBox(width: 12),
                _actionButton('Revenu', Icons.south_west, AppColors.green,
                    () => showAddTransaction(context, expense: false)),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: softShadow(0.1),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.savings_outlined, color: AppColors.green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Solde total',
                          style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(balance,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                      ),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _hide = !_hide),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.grey, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 16, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text(_hide ? 'Afficher' : 'Masquer',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.grey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const _SectionTitle('Rapports'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(
                        child: _Stat(Icons.south_west, 'Revenus',
                            money.format(store.periodIncome), AppColors.green)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _Stat(Icons.north_east, 'Dépenses',
                            '-${money.format(store.periodExpense)}', AppColors.ink)),
                  ]),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _editBudget(context, store),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('Budget du mois',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, color: AppColors.ink)),
                          const Spacer(),
                          Text('${(used * 100).round()} %',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: used >= 0.8 ? AppColors.danger : AppColors.green)),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: used.clamp(0.0, 1.0).toDouble()),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, w, __) => LinearProgressIndicator(
                              value: w,
                              minHeight: 10,
                              backgroundColor: AppColors.grey,
                              color: used >= 0.8 ? AppColors.danger : AppColors.green,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            used >= 1
                                ? 'Budget dépassé (${money.format(store.budget)})'
                                : 'Sur ${money.format(store.budget)} · touche pour modifier',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                  ),
                ),
                const _SectionTitle('Transactions'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: _PeriodTabs(store),
                ),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.savings_outlined,
                          size: 64, color: AppColors.green.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('Ne attends pas demain,\ncommence à suivre aujourd\'hui',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      const Text('Ajoute une dépense ou un revenu pour démarrer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    ]),
                  )
                else
                  for (final t in list.take(10)) TxnTile(t),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// Titre de section avec traits de part et d'autre, comme "Saving Reports".
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Row(children: [
          Expanded(child: Divider(color: AppColors.muted.withOpacity(0.35))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
          Expanded(child: Divider(color: AppColors.muted.withOpacity(0.35))),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration:
            BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ),
        ]),
      );
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs(this.store);
  final TxnStore store;

  @override
  Widget build(BuildContext context) {
    const labels = {Period.daily: 'Jour', Period.weekly: 'Semaine', Period.monthly: 'Mois'};
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        for (final e in labels.entries)
          Expanded(
            child: GestureDetector(
              onTap: () => store.setPeriod(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: store.period == e.key ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: store.period == e.key ? Colors.white : AppColors.ink))),
              ),
            ),
          ),
      ]),
    );
  }
}
