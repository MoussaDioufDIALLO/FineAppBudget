import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'models.dart';
import 'repositories.dart';

enum Period { daily, weekly, monthly }

class DayTotals {
  DayTotals(this.day, this.income, this.expense);
  final DateTime day;
  final double income;
  final double expense;
}

class TxnStore extends ChangeNotifier {
  TxnStore(this._prefs) {
    budget = _prefs.getDouble('budget') ?? 200000;
  }

  final SharedPreferences _prefs;
  List<Txn> items = [];
  Period period = Period.monthly;
  double budget = 200000;
  TxnRepository? _repo;
  StreamSubscription<List<Txn>>? _sub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;
  String? _key;
  String? _uid;

  /// Appelé à chaque changement d'authentification : bascule local <-> cloud.
  void bind(AuthService auth) {
    final key = auth.user?.uid ?? 'local';
    if (key == _key) return;
    _key = key;
    _sub?.cancel();
    _docSub?.cancel();
    _uid = auth.user?.uid;
    if (_uid != null) {
      _docSub = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots()
          .listen((d) {
        final b = d.data()?['budget'];
        if (b is num && b.toDouble() != budget) {
          budget = b.toDouble();
          _prefs.setDouble('budget', budget);
          notifyListeners();
        }
      }, onError: (Object e) => debugPrint('Budget cloud : $e'));
    }
    _repo = auth.user != null ? CloudRepo(auth.user!.uid) : LocalRepo(_prefs);
    items = [];
    _sub = _repo!.watch().listen((l) {
      items = l;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Erreur données : $e'));
  }

  void setPeriod(Period p) {
    period = p;
    notifyListeners();
  }

  Future<void> setBudget(double v) async {
    budget = v;
    await _prefs.setDouble('budget', v);
    if (_uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .set({'budget': v}, SetOptions(merge: true))
          .catchError((Object e) => debugPrint('Budget cloud : $e'));
    }
    notifyListeners();
  }

  /// Nombre de transactions créées en mode local, pas encore dans le cloud.
  int get localCount {
    final raw = _prefs.getString('local_txns');
    if (raw == null) return 0;
    try {
      return (jsonDecode(raw) as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Envoie les données locales vers le compte connecté, puis les retire du local.
  Future<int> importLocal() async {
    if (_uid == null) return 0;
    final local = LocalRepo(_prefs);
    final list = await local.watch().first;
    await Future.wait(list.map(_repo!.add)).timeout(const Duration(seconds: 20));
    await local.clear();
    notifyListeners();
    return list.length;
  }

  bool _inPeriod(Txn t, Period p) {
    final now = DateTime.now();
    switch (p) {
      case Period.daily:
        return t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day;
      case Period.weekly:
        return t.date.isAfter(now.subtract(const Duration(days: 7))) &&
            !t.date.isAfter(now);
      case Period.monthly:
        return t.date.year == now.year && t.date.month == now.month;
    }
  }

  List<Txn> get filtered => items.where((t) => _inPeriod(t, period)).toList();

  static double _sum(Iterable<Txn> l, bool expense) =>
      l.where((t) => t.isExpense == expense).fold(0.0, (s, t) => s + t.amount);

  double get income => _sum(items, false);
  double get expense => _sum(items, true);
  double get balance => income - expense;
  double get periodIncome => _sum(filtered, false);
  double get periodExpense => _sum(filtered, true);
  double get monthExpense =>
      _sum(items.where((t) => _inPeriod(t, Period.monthly)), true);
  double get budgetUsed => budget <= 0 ? 0 : (monthExpense / budget);

  /// 7 derniers jours (le plus ancien en premier).
  List<DayTotals> get last7 {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      final day = items.where((t) =>
          t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
      return DayTotals(d, _sum(day, false), _sum(day, true));
    });
  }

  Map<String, double> get expenseByCategory {
    final m = <String, double>{};
    for (final t in items.where((t) => t.isExpense)) {
      m[t.category] = (m[t.category] ?? 0) + t.amount;
    }
    return m;
  }

  // Pas d'await côté UI : Firestore ne répond qu'une fois connecté au serveur.
  Future<void> add(Txn t) => _repo!.add(t);
  Future<void> remove(String id) => _repo!.remove(id);
  Future<void> clearAll() => _repo!.clear();

  @override
  void dispose() {
    _sub?.cancel();
    _docSub?.cancel();
    super.dispose();
  }
}
