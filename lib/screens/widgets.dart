import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../theme.dart';
import '../txn_store.dart';

/// Ligne de transaction : carte arrondie, glisser vers la gauche pour supprimer.
class TxnTile extends StatelessWidget {
  const TxnTile(this.t, {super.key});
  final Txn t;

  @override
  Widget build(BuildContext context) {
    final cat = categoryOf(t.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Dismissible(
        key: ValueKey(t.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
              color: AppColors.danger, borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async =>
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Supprimer ?'),
                content: Text(t.title),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Supprimer')),
                ],
              ),
            ) ??
            false,
        onDismissed: (_) => context.read<TxnStore>().remove(t.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: softShadow(0.06),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(cat.icon, color: cat.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.dark, fontSize: 15)),
                Text(
                  '${DateFormat('d MMM', 'fr_FR').format(t.date)} • ${t.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.blue),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Text(
              '${t.isExpense ? '-' : '+'}${money.format(t.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: t.isExpense ? AppColors.blue : AppColors.income,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<void> showAddTransaction(BuildContext context, {bool expense = true}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => _AddSheet(expense: expense),
  );
}

class _AddSheet extends StatefulWidget {
  const _AddSheet({this.expense = true});
  final bool expense;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  late bool _expense = widget.expense;
  late String _cat = (widget.expense ? expenseCategories : incomeCategories).first.name;
  DateTime _date = DateTime.now();
  String? _err;

  List<Category> get _cats => _expense ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.').replaceAll(' ', ''));
    if (_title.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _err = 'Titre et montant valides requis.');
      return;
    }
    context.read<TxnStore>().add(Txn(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: _title.text.trim(),
          amount: amount,
          isExpense: _expense,
          category: _cat,
          date: _date,
        ));
    Navigator.pop(context);
  }

  Widget _typeTab(String label, bool expense) {
    final on = _expense == expense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _expense = expense;
          _cat = _cats.first.name;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: on ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text('Nouvelle transaction',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: AppColors.field, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [_typeTab('Dépense', true), _typeTab('Revenu', false)]),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amount,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: _expense ? AppColors.blue : AppColors.income),
              decoration: const InputDecoration(hintText: '0', suffixText: 'FCFA'),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _title, decoration: const InputDecoration(labelText: 'Titre')),
            const SizedBox(height: 16),
            const Text('Catégorie',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in _cats)
                ChoiceChip(
                  avatar: Icon(c.icon, size: 18, color: AppColors.dark),
                  label: Text(c.name),
                  selected: _cat == c.name,
                  showCheckmark: false,
                  selectedColor: AppColors.green,
                  backgroundColor: AppColors.field,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  onSelected: (_) => setState(() => _cat = c.name),
                ),
            ]),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(DateFormat('d MMMM y', 'fr_FR').format(_date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_err!, style: const TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
