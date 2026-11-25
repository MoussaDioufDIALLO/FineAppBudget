import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../theme.dart';
import '../txn_store.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TxnStore>();
    final days = store.last7;
    final cats = store.expenseByCategory;
    final catTotal = cats.values.fold(0.0, (a, b) => a + b);
    final entries = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxY = days
        .map((d) => d.income > d.expense ? d.income : d.expense)
        .fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              const Text('Analyse',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _Head('Solde total', money.format(store.balance), AppColors.dark)),
                Expanded(
                    child: _Head('Dépenses', '-${money.format(store.expense)}', AppColors.blue)),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
                color: const Color(0xFFDFF7E2), borderRadius: BorderRadius.circular(28)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Revenus et dépenses (7 derniers jours)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(BarChartData(
                  maxY: maxY == 0 ? 1 : maxY * 1.15,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                              DateFormat('E', 'fr_FR').format(days[v.toInt()].day),
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < days.length; i++)
                      BarChartGroupData(x: i, barsSpace: 3, barRods: [
                        BarChartRodData(
                            toY: days[i].income, color: AppColors.green, width: 9,
                            borderRadius: BorderRadius.circular(3)),
                        BarChartRodData(
                            toY: days[i].expense, color: AppColors.blue, width: 9,
                            borderRadius: BorderRadius.circular(3)),
                      ]),
                  ],
                )),
              ),
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.circle, size: 10, color: AppColors.green),
                SizedBox(width: 4),
                Text('Revenus'),
                SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: AppColors.blue),
                SizedBox(width: 4),
                Text('Dépenses'),
              ]),
            ]),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Text('Dépenses par catégorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        if (cats.isEmpty)
          const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Pas encore de dépenses à analyser.')))
        else ...[
          SizedBox(
            height: 220,
            child: PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 46,
              sections: [
                for (final e in entries)
                  PieChartSectionData(
                    value: e.value,
                    color: categoryOf(e.key).color,
                    radius: 60,
                    title: '${(e.value / catTotal * 100).round()}%',
                    titleStyle:
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
              ],
            )),
          ),
          for (final e in entries)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: categoryOf(e.key).color.withOpacity(0.18),
                child: Icon(categoryOf(e.key).icon, color: categoryOf(e.key).color),
              ),
              title: Text(e.key),
              trailing: Text(money.format(e.value),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ],
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.label, this.value, this.color);
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: const TextStyle(color: AppColors.dark)),
        FittedBox(
          child: Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ),
      ]);
}
