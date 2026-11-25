import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'profile_page.dart';
import 'stats_page.dart';
import 'transactions_page.dart';
import 'widgets.dart';

/// Mobile : barre de navigation en bas. Desktop / tablette : rail latéral.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    TransactionsPage(),
    StatsPage(),
    ProfilePage(),
  ];
  static const _labels = ['Accueil', 'Transactions', 'Stats', 'Profil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.swap_horiz,
    Icons.pie_chart_outline,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _pages[_i],
      ),
    );
    return Scaffold(
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _i,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => setState(() => _i = i),
                destinations: [
                  for (var k = 0; k < _labels.length; k++)
                    NavigationRailDestination(
                        icon: Icon(_icons[k]), label: Text(_labels[k])),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Color(0xFFDFF7E2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (var k = 0; k < _labels.length; k++)
                        Semantics(
                          label: _labels[k],
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _i = k),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 56,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _i == k ? const Color(0xFF00D09E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(_icons[k],
                                  size: 26, color: const Color(0xFF052224)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: _i <= 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF00D09E),
              onPressed: () => showAddTransaction(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
