import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'profile_page.dart';
import 'spending_tracker.dart';
import '../utils/recalculate_balance.dart';

final currencyFormatter = NumberFormat.decimalPattern();

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
        'type': tx.transactionType,
        'cur': tx.currency,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get filtered {
    List<Map<String, dynamic>> txs = _transactions;

    if (selectedCategory != 'All') {
      if (selectedCategory == 'Income') {
        txs = txs.where((tx) => tx['type'] == 'Income').toList();
      } else {
        txs = txs
            .where(
              (tx) =>
                  tx['type'] == 'Expense' && tx['category'] == selectedCategory,
            )
            .toList();
      }
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

                    final txWidgets = entry.value.map((tx) {
                      final isIncome = tx['type'] == 'Income';

                      return ListTile(
                        leading: Icon(
                          isIncome ? Icons.attach_money : Icons.money_off,
                          color: isIncome ? Colors.green[700] : Colors.red[700],
                        ),
                        title: Text(
                          tx["description"],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isIncome
                                ? Colors.green[800]
                                : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          isIncome ? "Income" : tx["category"],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        trailing: Text(
                          "${tx["cur"]} ${isIncome ? "+ " : "- "}${currencyFormatter.format(tx["amount"].abs())}",
                          style: TextStyle(
                            color: isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onLongPress: () async {
                          bool isSavingsTx =
                              tx['type'] == 'Expense' &&
                              tx['category'] == 'Savings';
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete this transaction?"),
                              content: Text(
                                isSavingsTx
                                    ? "⚠️ This is a savings transaction. Deleting it may affect your savings progress. Continue?"
                                    : "This action cannot be undone.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          final allTx = _box.values.toList();

                          try {
                            final txToDelete = allTx.firstWhere(
                              (t) =>
                                  t.amount == tx['amount'] &&
                                  t.description == tx['description'] &&
                                  t.category == tx['category'] &&
                                  t.transactionType == tx['type'] &&
                                  t.currency == tx['cur'] &&
                                  DateTime(t.year, t.month, t.date!) ==
                                      tx['date'],
                            );

                            final key = _box.keyAt(allTx.indexOf(txToDelete));
                            await _box.delete(key);
                            setState(() {}); // Refresh UI
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to delete transaction."),
                              ),
                            );
                          }
                        },
                      );
                    });

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
