import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_service.dart';
import '../theme.dart';
import '../txn_store.dart';
import 'notifications_page.dart';
import 'widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TxnStore>();
    final auth = context.watch<AuthService>();
    final list = store.filtered;
    final used = store.budgetUsed;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bonjour, ${auth.displayName}',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
                      Row(children: [
                        Icon(auth.user != null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                            size: 16, color: AppColors.dark),
                        const SizedBox(width: 6),
                        Text(auth.user != null ? 'Synchronisé' : 'Mode local',
                            style: const TextStyle(color: AppColors.dark)),
                      ]),
                    ]),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.mint, foregroundColor: AppColors.dark),
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const NotificationsPage())),
                  ),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _Total('Solde total', money.format(store.balance), AppColors.dark)),
                  Container(width: 1, height: 44, color: AppColors.dark.withOpacity(0.3)),
                  Expanded(
                      child: _Total('Dépenses', '-${money.format(store.expense)}', AppColors.blue)),
                ]),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _editBudget(context, store),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                        color: AppColors.mint, borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: used.clamp(0.0, 1.0).toDouble()),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, w, __) => FractionallySizedBox(
                          widthFactor: w,
                          child: Container(
                              color: used >= 0.8 ? AppColors.danger : AppColors.dark),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(children: [
                          Text('${(used * 100).round()} %',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: used > 0.12 ? Colors.white : AppColors.dark)),
                          const Spacer(),
                          Text(money.format(store.budget),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: AppColors.dark)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(used >= 0.8 ? Icons.warning_amber_rounded : Icons.check_box_outlined,
                      size: 18, color: AppColors.dark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                        used >= 1
                            ? 'Budget du mois dépassé'
                            : used >= 0.8
                                ? '${(used * 100).round()} % du budget du mois utilisé : attention'
                                : '${(used * 100).round()} % du budget du mois utilisé, ça va',
                        style: const TextStyle(color: AppColors.dark)),
                  ),
                ]),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(24),
                boxShadow: softShadow(0.12)),
            child: Row(children: [
              Expanded(
                  child: _Mini(Icons.arrow_downward, 'Revenus', money.format(store.periodIncome),
                      AppColors.dark)),
              Container(width: 1, height: 44, color: AppColors.dark.withOpacity(0.3)),
              const SizedBox(width: 16),
              Expanded(
                  child: _Mini(Icons.arrow_upward, 'Dépenses', '-${money.format(store.periodExpense)}',
                      AppColors.blue)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: _PeriodTabs(store),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 4),
          child: Text('Transactions récentes',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark)),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              Icon(Icons.receipt_long_outlined,
                  size: 56, color: AppColors.dark.withOpacity(0.25)),
              const SizedBox(height: 8),
              Text('Aucune transaction sur cette période.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.dark.withOpacity(0.6))),
              const SizedBox(height: 4),
              Text('Appuie sur + pour en ajouter une.',
                  style: TextStyle(fontSize: 12, color: AppColors.dark.withOpacity(0.45))),
            ]),
          )
        else
          for (final t in list.take(10)) TxnTile(t),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: const TextStyle(color: AppColors.dark)),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        ),
      ]);
}

class _Mini extends StatelessWidget {
  const _Mini(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.dark),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$label (période)',
                style: const TextStyle(fontSize: 12, color: AppColors.dark)),
            FittedBox(
              child: Text(value,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            ),
          ]),
        ),
      ]);
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs(this.store);
  final TxnStore store;

  @override
  Widget build(BuildContext context) {
    const labels = {Period.daily: 'Jour', Period.weekly: 'Semaine', Period.monthly: 'Mois'};
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: AppColors.field, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        for (final e in labels.entries)
          Expanded(
            child: GestureDetector(
              onTap: () => store.setPeriod(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: store.period == e.key ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                    child: Text(e.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.dark))),
              ),
            ),
          ),
      ]),
    );
  }
}
