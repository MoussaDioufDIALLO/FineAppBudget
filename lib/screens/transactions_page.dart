import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../txn_store.dart';
import 'widgets.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TxnStore>();
    final items = store.items;
    final rows = <Widget>[];
    String? last;
    for (final t in items) {
      final key = DateFormat('MMMM y', 'fr_FR').format(t.date);
      if (key != last) {
        last = key;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
          child: Text(key[0].toUpperCase() + key.substring(1),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ));
      }
      rows.add(TxnTile(t));
    }
    return ColoredBox(
      color: AppColors.grey,
      child: Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              const Text('Transactions',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: softShadow(0.1)),
                child: Column(children: [
                  const Text('Solde total', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  Text(money.format(store.balance),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 56, color: AppColors.dark.withOpacity(0.25)),
                    const SizedBox(height: 8),
                    Text('Aucune transaction.',
                        style: TextStyle(color: AppColors.dark.withOpacity(0.6))),
                  ]),
                )
              : ListView(padding: const EdgeInsets.only(bottom: 96), children: rows),
        ),
      ],
    ));
  }
}
