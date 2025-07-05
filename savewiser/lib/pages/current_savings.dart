import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'transaction_list.dart';
import 'spending_tracker.dart';

class CurrentSavingsPage extends StatefulWidget {
  const CurrentSavingsPage({super.key});

  @override
  State<CurrentSavingsPage> createState() => _CurrentSavingsPageState();
}

class _CurrentSavingsPageState extends State<CurrentSavingsPage> {
  late Box<Transaction> _box;
  late List<Map<String, int>> _recentMonths;
  late Map<String, int> _selectedMonthYear;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Transaction>('transactions');
    _recentMonths = _getRecentMonths(_box.values.toList());
    _selectedMonthYear = _recentMonths.isNotEmpty
        ? _recentMonths.first
        : {'year': DateTime.now().year, 'month': DateTime.now().month};
  }

  List<Map<String, int>> _getRecentMonths(List<Transaction> transactions) {
    final Set<String> uniqueExpenseKeys = {};

    for (var tx in transactions) {
      if (tx.transactionType == 'Expense') {
        final key = '${tx.year}-${tx.month.toString().padLeft(2, '0')}';
        uniqueExpenseKeys.add(key);
      }
    }

    final List<Map<String, int>> uniqueMonths = uniqueExpenseKeys.map((key) {
      final parts = key.split('-');
      return {'year': int.parse(parts[0]), 'month': int.parse(parts[1])};
    }).toList();

    uniqueMonths.sort((a, b) {
      final aDate = DateTime(a['year']!, a['month']!);
      final bDate = DateTime(b['year']!, b['month']!);
      return bDate.compareTo(aDate);
    });

    return uniqueMonths.take(5).toList();
  }

  String _formatMonthYear(Map<String, int> map) {
    final date = DateTime(map['year']!, map['month']!);
    return DateFormat('MMMM yyyy').format(date);
  }

  double _calculateBalance(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double _calculateUsableBalance(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double _calculatecpfBalance(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, tx) => sum + tx.cpfPortion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<Transaction> box, _) {
          final allTransactions = box.values.toList();
          final filteredTransactions = allTransactions.where((tx) {
            return tx.month == _selectedMonthYear['month'] &&
                tx.year == _selectedMonthYear['year'];
          }).toList();

          final balance = _calculateBalance(allTransactions);
          final usableBalance = _calculateUsableBalance(allTransactions);
          final cpfBalance = _calculatecpfBalance(allTransactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'SAVEWISER',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[900],
                    ),
                  ),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Total Balance: ${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),

                      // Usable Balance
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Usable Balance: ${usableBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: usableBalance >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),

                      // CPF Balance
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'CPF Balance: ${cpfBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: cpfBalance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),

                      DropdownButton<Map<String, int>>(
                        value: _selectedMonthYear,
                        isExpanded: true,
                        items: _recentMonths.map((monthMap) {
                          return DropdownMenuItem(
                            value: monthMap,
                            child: Text(
                              _formatMonthYear(monthMap),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMonthYear = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      SavingsPieChart(
                        transactions: filteredTransactions,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionListPage(
                                transactions: filteredTransactions.map((tx) {
                                  return {
                                    "description": tx.description ?? '',
                                    "amount": tx.amount,
                                    "category": tx.category,
                                    "date": DateTime(
                                      tx.year,
                                      tx.month,
                                      tx.date!,
                                    ),
                                  };
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionListPage(
                                  transactions: filteredTransactions.map((tx) {
                                    return {
                                      "description": tx.description ?? '',
                                      "amount": tx.amount,
                                      "category": tx.category,
                                      "date": DateTime(
                                        tx.year,
                                        tx.month,
                                        tx.date!,
                                      ),
                                    };
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                          child: const Text("See Transaction History"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpendingTrackerPage()),
          );
        },
        // backgroundColor: const Color.fromARGB(255, 255, 178, 250),
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}

class SavingsPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onTap;

  const SavingsPieChart({
    super.key,
    required this.transactions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Store totals for each category
    final Map<String, double> categoryTotals = {
      "Needs": 0.0,
      "Wants": 0.0,
      "Savings": 0.0,
    };

    // Calculate totals for each category
    for (final tx in transactions) {
      if (tx.transactionType != 'Expense') continue;

      if (categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount.abs();
      }
    }

    // Calculate the total expenses
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return const Center(child: Text("No expense data available"));
    }

    final colors = [Colors.blue, Colors.red.shade700, Colors.green.shade700];

    // Pie chart sections
    final sections = List.generate(categoryTotals.length, (index) {
      final category = categoryTotals.keys.elementAt(index);
      final value = categoryTotals[category]!;
      final percentage = (value / total) * 100;

      return PieChartSectionData(
        color: colors[index],
        value: value,
        title: "${percentage.toStringAsFixed(1)}%",
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Pie chart itself
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 0,
                pieTouchData: PieTouchData(enabled: false),
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 20), // Space between the pie chart and legend
          // Legend below the pie chart
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(categoryTotals.length, (index) {
              final category = categoryTotals.keys.elementAt(index);
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  children: [
                    // Color box for the legend
                    Container(width: 20, height: 20, color: colors[index]),
                    const SizedBox(width: 8),
                    // Category label
                    Text(category, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
