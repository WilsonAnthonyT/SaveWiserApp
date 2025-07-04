import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'profile_page.dart';
import 'spending_tracker.dart';

class TransactionListPage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions; // Define transactions

  // Accept transactions as a named parameter
  const TransactionListPage({super.key, required this.transactions});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'Date';
  late Box<Transaction> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Transaction>('transactions');
  }

  List<Map<String, dynamic>> get _transactions {
    return _box.values.map((tx) {
      return {
        'amount': tx.amount,
        'category': tx.category,
        'description': tx.description ?? '',
        'date': DateTime(tx.year, tx.month, tx.date!),
      };
    }).toList();
  }

  List<Map<String, dynamic>> get filtered {
    List<Map<String, dynamic>> txs = _transactions;

    if (selectedCategory != 'All') {
      txs = txs.where((tx) => tx['category'] == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      txs = txs
          .where(
            (tx) => tx['description'].toString().toLowerCase().contains(
              searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    txs.sort((a, b) {
      if (sortBy == 'Date') {
        return b['date'].compareTo(a['date']);
      } else {
        return b['amount'].abs().compareTo(a['amount'].abs());
      }
    });

    return txs;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var tx in filtered) {
      final date = DateFormat.yMMMMd().format(tx['date']);
      grouped.putIfAbsent(date, () => []).add(tx);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                const Text(
                  'SAVEWISER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: sortBy,
                        onChanged: (val) => setState(() => sortBy = val!),
                        items: const [
                          DropdownMenuItem(
                            value: 'Date',
                            child: Text('Sort by Date'),
                          ),
                          DropdownMenuItem(
                            value: 'Value',
                            child: Text('Sort by Value'),
                          ),
                        ],
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: selectedCategory,
                        onChanged: (val) =>
                            setState(() => selectedCategory = val!),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('Show All'),
                          ),
                          DropdownMenuItem(
                            value: 'Needs',
                            child: Text('Needs'),
                          ),
                          DropdownMenuItem(
                            value: 'Wants',
                            child: Text('Wants'),
                          ),
                          DropdownMenuItem(
                            value: 'Income',
                            child: Text('Income'),
                          ),
                          DropdownMenuItem(
                            value: 'Savings',
                            child: Text('Savings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...grouped.entries.expand((entry) {
                    final dateLabel = Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                    final txWidgets = entry.value.map(
                      (tx) => ListTile(
                        leading: const Icon(Icons.monetization_on),
                        title: Text(tx["description"]),
                        subtitle: Text(tx["category"]),
                        trailing: Text(
                          "${tx["amount"] >= 0 ? "+" : "-"}\$${(tx["amount"].abs() / 1000).toStringAsFixed(1)}k",
                          style: TextStyle(
                            color: tx["amount"] >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                    return [dateLabel, ...txWidgets];
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpendingTrackerPage()),
          ).then((_) => setState(() {})); // Refresh after return
        },
        //backgroundColor: Colors.indigo[900],
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}
