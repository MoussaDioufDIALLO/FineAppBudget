import 'package:flutter/material.dart';

class Category {
  const Category(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

const expenseCategories = [
  Category('Alimentation', Icons.restaurant, Color(0xFF00D09E)),
  Category('Transport', Icons.directions_bus, Color(0xFF0068FF)),
  Category('Logement', Icons.home_outlined, Color(0xFF6DB6FE)),
  Category('Loisirs', Icons.movie_outlined, Color(0xFFF2A93B)),
  Category('Santé', Icons.favorite_border, Color(0xFFE5575B)),
  Category('Autre', Icons.category_outlined, Color(0xFF8A9A9B)),
];

const incomeCategories = [
  Category('Salaire', Icons.payments_outlined, Color(0xFF00D09E)),
  Category('Vente', Icons.storefront_outlined, Color(0xFF0068FF)),
  Category('Autre', Icons.category_outlined, Color(0xFF8A9A9B)),
];

Category categoryOf(String name) => [...expenseCategories, ...incomeCategories]
    .firstWhere((c) => c.name == name, orElse: () => expenseCategories.last);

class Txn {
  Txn({
    required this.id,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isExpense;
  final DateTime date;

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'isExpense': isExpense,
        'category': category,
        'date': date.millisecondsSinceEpoch,
      };

  factory Txn.fromMap(String id, Map<String, dynamic> m) => Txn(
        id: id,
        title: m['title'] as String? ?? '',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        isExpense: m['isExpense'] as bool? ?? true,
        category: m['category'] as String? ?? 'Autre',
        date: DateTime.fromMillisecondsSinceEpoch((m['date'] as num?)?.toInt() ?? 0),
      );
}
