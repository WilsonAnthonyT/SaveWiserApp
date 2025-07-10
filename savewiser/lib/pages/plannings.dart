import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart' as HiveTransaction;
import 'spending_tracker.dart';

typedef Category = String;

class Transaction {
  final String name;
  final Category category;
  final double amount;
  final DateTime timestamp;

  Transaction({
    required this.name,
    required this.category,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      name: json['name'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class PlanningsPage extends StatefulWidget {
  const PlanningsPage({Key? key}) : super(key: key);

  @override
  _PlanningsPageState createState() => _PlanningsPageState();
}

class _PlanningsPageState extends State<PlanningsPage> {
  final List<Transaction> _transactions = [];
  String _filter = 'All';
  late SharedPreferences _prefs;
  static const _storageKey = 'daily_planner_transactions';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _prefs = await SharedPreferences.getInstance();
    final String? data = _prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      setState(() {
        _transactions.clear();
        _transactions.addAll(
          list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)),
        );
      });
    }
  }

  Future<void> _saveTransactions() async {
    final String data = jsonEncode(
      _transactions.map((t) => t.toJson()).toList(),
    );
    await _prefs.setString(_storageKey, data);
  }

  Future<void> _completeTransaction(int index) async {
    final localTx = _transactions[index];

    // 1️⃣ add to Hive 'transactions' box
    final box = Hive.box<HiveTransaction.Transaction>('transactions');
    await box.add(
      HiveTransaction.Transaction(
        category: localTx.category,
        amount: localTx.amount.abs(),
        month: localTx.timestamp.month,
        year: localTx.timestamp.year,
        date: localTx.timestamp.day,
        transactionType: localTx.amount > 0 ? 'Income' : 'Expense',
        description: localTx.name,
        currency: 'IDR',
        cpfPortion: 0,
        usablePortion: localTx.amount.abs(),
      ),
    );

    // 2️⃣ remove from planning list & persist
    setState(() => _transactions.removeAt(index));
    await _saveTransactions();

    // 3️⃣ feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${localTx.name}” moved to Transaction History')),
      );
    }
  }

  void _addTransaction() {
    String name = '';
    String amountText = '';
    String selectedCategory = 'Needs';
    final amountController = TextEditingController();
    final formatter = NumberFormat.decimalPattern('en_US');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  final numeric = val.replaceAll(',', '');
                  if (numeric.isEmpty) return;
                  final parsed = int.parse(numeric);
                  final newText = formatter.format(parsed);
                  setModalState(() {
                    amountController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  });
                  amountText = numeric;
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Needs', 'Wants'].map((cat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) => setModalState(() => selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountText) ?? 0;
                if (name.isNotEmpty && amount != 0) {
                  setState(() {
                    _transactions.add(Transaction(
                      name: name,
                      category: selectedCategory.toLowerCase(),
                      amount: selectedCategory.toLowerCase() == 'needs' ? -amount : amount,
                      timestamp: DateTime.now(),
                    ));
                  });
                  _saveTransactions();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todaysTransactions = _transactions.where((t) {
      return t.timestamp.year == today.year &&
          t.timestamp.month == today.month &&
          t.timestamp.day == today.day;
    }).toList();

    final totalSpent = todaysTransactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = todaysTransactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
    final net = totalIncome + totalSpent;

    final filtered = _filter == 'All'
        ? todaysTransactions
        : todaysTransactions
        .where((t) => t.category.toLowerCase() == _filter.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Plannings'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary metrics
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saved Today', style: TextStyle(fontSize: 16)),
                    Text(
                      NumberFormat.simpleCurrency(locale: 'id_ID').format(totalIncome),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spent Today', style: TextStyle(fontSize: 16)),
                    Text(
                      NumberFormat.simpleCurrency(locale: 'id_ID').format(totalSpent),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Net', style: TextStyle(fontSize: 16)),
                    Text(
                      NumberFormat.simpleCurrency(locale: 'id_ID').format(net),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Needs', 'Wants']
                  .map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Plan list with checklist
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No plans for today.'))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final tx = filtered[i];
                return ListTile(
                  title: Text(tx.name),
                  subtitle: Text(DateFormat('hh:mm a').format(tx.timestamp)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.simpleCurrency(locale: 'id_ID').format(tx.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.amount > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () => _completeTransaction(i),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
