import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../theme.dart';
import '../txn_store.dart';
import 'ui.dart';

/// Notifications générées à partir de vos données (pas de serveur de push).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TxnStore>();
    final used = store.budgetUsed;
    final tiles = <Widget>[
      if (used >= 0.8)
        _N(Icons.warning_amber_rounded, used >= 1 ? 'Budget dépassé' : 'Budget presque atteint',
            'Vous avez utilisé ${(used * 100).round()} % de votre budget mensuel.', null),
      for (final t in store.items.take(15))
        _N(
          categoryOf(t.category).icon,
          t.isExpense ? 'Dépense enregistrée' : 'Revenu enregistré',
          '${t.title} • ${t.category} • ${t.isExpense ? '-' : '+'}${money.format(t.amount)}',
          t.date,
        ),
    ];
    return FwScaffold(
      title: 'Notifications',
      child: tiles.isEmpty
          ? const Center(child: Text('Aucune notification.'))
          : ListView(padding: const EdgeInsets.all(20), children: tiles),
    );
  }
}

class _N extends StatelessWidget {
  const _N(this.icon, this.title, this.body, this.date);
  final IconData icon;
  final String title, body;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        leading: CircleAvatar(
            backgroundColor: AppColors.green, child: Icon(icon, color: AppColors.dark)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(date == null ? body : '$body\n${DateFormat('d MMM y', 'fr_FR').format(date!)}'),
        isThreeLine: date != null,
      ),
      const Divider(height: 1),
    ]);
  }
}
