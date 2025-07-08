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
  final List<Transaction> _transactions = [];
  String _filter = 'All';

  void _addTransaction() {
    String description = '';
    String amountText = '';
    String selectedCategory = 'Needs';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (val) => description = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (val) => amountText = val,
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
                      onSelected: (_) {
                        setModalState(() {
                          selectedCategory = cat;
                        });
                      },
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
                if (description.isNotEmpty && amount != 0) {
                  setState(() {
                    _transactions.add(Transaction(
                      description: description,
                      category: selectedCategory.toLowerCase(),
                      amount: amount,
                      timestamp: DateTime.now(),
                    ));
                  });
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

  void _completeTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
    // TODO: move this transaction into the permanent log
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
                      NumberFormat.simpleCurrency(locale: 'id_ID')
                          .format(totalIncome),
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
              children: ['All', 'Needs', 'Wants']
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
                  title: Text(tx.description),
                  subtitle: Text(
                    DateFormat('hh:mm a').format(tx.timestamp),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        NumberFormat.simpleCurrency(locale: 'id_ID')
                            .format(tx.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.amount > 0
                              ? Colors.green
                              : Colors.red,
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
