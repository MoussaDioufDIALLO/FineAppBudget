import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'profile_page.dart';
import 'stats_page.dart';
import 'transactions_page.dart';
import '../theme.dart';
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
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: softShadow(0.08),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    for (var k = 0; k < _labels.length; k++)
                      Expanded(
                        child: Semantics(
                          label: _labels[k],
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _i = k),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 62,
                              decoration: BoxDecoration(
                                gradient: _i == k
                                    ? LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppColors.green.withOpacity(0.18),
                                          Colors.white,
                                        ],
                                      )
                                    : null,
                                border: Border(
                                  top: BorderSide(
                                    color: _i == k ? AppColors.green : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_icons[k],
                                      size: 24,
                                      color: _i == k ? AppColors.green : AppColors.ink),
                                  const SizedBox(height: 3),
                                  Text(_labels[k],
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _i == 1
          ? FloatingActionButton(
              backgroundColor: AppColors.green,
              onPressed: () => showAddTransaction(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
