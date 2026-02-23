// lib/providers/finance_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

enum TransactionType { income, expense }

class FinanceTransaction {
  final String id;
  final String userId;
  final TransactionType type;
  final String category;
  final String description;
  final double amount;
  final DateTime date;
  final String? cropOrAnimal;
  final String? notes;

  const FinanceTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.cropOrAnimal,
    this.notes,
  });

  bool get isIncome => type == TransactionType.income;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'crop_or_animal': cropOrAnimal,
        'notes': notes,
      };

  factory FinanceTransaction.fromMap(
      Map<String, dynamic> m) =>
      FinanceTransaction(
        id: m['id'],
        userId: m['user_id'],
        type: m['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        category: m['category'],
        description: m['description'],
        amount: (m['amount'] as num).toDouble(),
        date: DateTime.parse(m['date']),
        cropOrAnimal: m['crop_or_animal'],
        notes: m['notes'],
      );
}

class FinanceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<FinanceTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<FinanceTransaction> get transactions =>
      _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpenses => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  double get netProfit => totalIncome - totalExpenses;

  List<FinanceTransaction> get recentTransactions =>
      _transactions.take(10).toList();

  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => !t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  Map<String, double> get incomeByCategory {
    final map = <String, double>{};
    for (final t in _transactions.where((t) => t.isIncome)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return Map.fromEntries(map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  Future<void> loadTransactions(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await _db.database;
      // Create table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS finance_transactions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          crop_or_animal TEXT,
          notes TEXT
        )
      ''');
      final maps = await db.query(
        'finance_transactions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      _transactions =
          maps.map(FinanceTransaction.fromMap).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction({
    required String userId,
    required TransactionType type,
    required String category,
    required String description,
    required double amount,
    required DateTime date,
    String? cropOrAnimal,
    String? notes,
  }) async {
    try {
      final db = await _db.database;
      final id =
          DateTime.now().millisecondsSinceEpoch.toString();
      final tx = FinanceTransaction(
        id: id,
        userId: userId,
        type: type,
        category: category,
        description: description,
        amount: amount,
        date: date,
        cropOrAnimal: cropOrAnimal,
        notes: notes,
      );
      await db.insert('finance_transactions', tx.toMap());
      _transactions.insert(0, tx);
      _sortTransactions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final db = await _db.database;
      await db.delete('finance_transactions',
          where: 'id = ?', whereArgs: [id]);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // Get transactions for a specific month/year
  List<FinanceTransaction> getByMonth(
      int month, int year) {
    return _transactions
        .where((t) =>
            t.date.month == month && t.date.year == year)
        .toList();
  }

  // Income categories
  static const List<String> incomeCategories = [
    'Crop Sales',
    'Livestock Sales',
    'Milk Sales',
    'Egg Sales',
    'Contract Farming',
    'Government Support',
    'Loan / Credit',
    'Other Income',
  ];

  // Expense categories
  static const List<String> expenseCategories = [
    'Seeds',
    'Fertilizer',
    'Chemicals / Pesticides',
    'Animal Feed',
    'Veterinary / Medicine',
    'Labour / Wages',
    'Fuel & Transport',
    'Equipment & Repairs',
    'Irrigation',
    'Land Preparation',
    'Loan Repayment',
    'Other Expense',
  ];
}