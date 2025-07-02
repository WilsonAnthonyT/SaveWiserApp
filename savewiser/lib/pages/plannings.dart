import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Simple transaction model
typedef Category = String;

class Transaction {
  final String description;
  final Category category;
  final double amount;
  final DateTime timestamp;

  Transaction({
    required this.description,
    required this.category,
    required this.amount,
    required this.timestamp,
  });
}

class PlanningsPage extends StatefulWidget {
  const PlanningsPage({Key? key}) : super(key: key);

  @override
  _PlanningsPageState createState() => _PlanningsPageState();
}

class _PlanningsPageState extends State<PlanningsPage> {
  final List<Transaction> _transactions = [
    Transaction(
      description: 'Breakfast',
      category: 'needs',
      amount: -15.00,
      timestamp: DateTime.now(),
    ),
    Transaction(
      description: 'Coffee',
      category: 'wants',
      amount: -10.00,
      timestamp: DateTime.now(),
    ),
    Transaction(
      description: 'Salary',
      category: 'income',
      amount: 100.00,
      timestamp: DateTime.now(),
    ),
  ];

  String _filter = 'All';

  void _addTransaction() {
    // TODO: implement navigation or dialog for adding a new transaction
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
        .where((t) =>
    _filter == 'Income'
        ? t.amount > 0
        : t.category.toLowerCase() == _filter.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Plannings'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary metricsw
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
                      NumberFormat.simpleCurrency(locale: 'id_ID')
                          .format(totalIncome + (totalSpent.abs() * 0)),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spent Today', style: TextStyle(fontSize: 16)),
                    Text(
                      NumberFormat.simpleCurrency(locale: 'id_ID')
                          .format(totalSpent),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Net', style: TextStyle(fontSize: 16)),
                    Text(
                      NumberFormat.simpleCurrency(locale: 'id_ID')
                          .format(net),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
              children: ['All', 'Needs', 'Wants', 'Income']
                  .map(
                    (f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) {
                      setState(() => _filter = f);
                    },
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Transaction list
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No transactions for today.'))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final tx = filtered[i];
                return ListTile(
                  leading: Icon(
                    tx.amount > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    color: tx.amount > 0 ? Colors.green : Colors.red,
                  ),
                  title: Text(tx.description),
                  subtitle: Text(
                    DateFormat('hh:mm a').format(tx.timestamp),
                  ),
                  trailing: Text(
                    NumberFormat.simpleCurrency(locale: 'id_ID')
                        .format(tx.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.amount > 0 ? Colors.green : Colors.red,
                    ),
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
