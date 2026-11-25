import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract class TxnRepository {
  Stream<List<Txn>> watch();
  Future<void> add(Txn t);
  Future<void> remove(String id);
  Future<void> clear();
}

/// Stockage local (mode hors-ligne / sans compte).
class LocalRepo implements TxnRepository {
  LocalRepo(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => Txn.fromMap((e as Map)['id'] as String, Map<String, dynamic>.from(e)))
          .toList();
    }
    _sort();
  }

  static const _key = 'local_txns';
  final SharedPreferences _prefs;
  List<Txn> _items = [];
  final _c = StreamController<List<Txn>>.broadcast();

  void _sort() => _items.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _save() async {
    _sort();
    await _prefs.setString(
      _key,
      jsonEncode(_items.map((t) => {'id': t.id, ...t.toMap()}).toList()),
    );
    _c.add(List.unmodifiable(_items));
  }

  @override
  Stream<List<Txn>> watch() async* {
    yield List.unmodifiable(_items);
    yield* _c.stream;
  }

  @override
  Future<void> add(Txn t) async {
    _items.add(t);
    await _save();
  }

  @override
  Future<void> remove(String id) async {
    _items.removeWhere((t) => t.id == id);
    await _save();
  }

  @override
  Future<void> clear() async {
    _items.clear();
    await _save();
  }
}

/// Stockage Firestore : users/{uid}/transactions (synchronisé entre appareils).
class CloudRepo implements TxnRepository {
  CloudRepo(String uid)
      : _col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('transactions');

  final CollectionReference<Map<String, dynamic>> _col;

  @override
  Stream<List<Txn>> watch() => _col
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Txn.fromMap(d.id, d.data())).toList());

  @override
  Future<void> add(Txn t) => _col.doc(t.id).set(t.toMap());

  @override
  Future<void> remove(String id) => _col.doc(id).delete();

  @override
  Future<void> clear() async {
    final snap = await _col.get();
    // Un batch Firestore accepte 500 opérations max.
    for (var i = 0; i < snap.docs.length; i += 400) {
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs.skip(i).take(400)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}
