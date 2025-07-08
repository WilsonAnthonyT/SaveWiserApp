import 'package:flutter/material.dart';
//import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'transaction_list.dart';
import 'spending_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currencyFormatter = NumberFormat.decimalPattern();

class MonthYear {
  final int year;
  final int month;

  MonthYear({required this.year, required this.month});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYear &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;

  @override
  String toString() => '$month/$year';
}

class CurrentSavingsPage extends StatefulWidget {
  const CurrentSavingsPage({super.key});

  @override
  State<CurrentSavingsPage> createState() => _CurrentSavingsPageState();
}

class _CurrentSavingsPageState extends State<CurrentSavingsPage> {
  late Box<Transaction> _box;
  late List<MonthYear> _recentMonths;
  late MonthYear _selectedMonthYear;
  String _targetAmount = '';
  //bool _homeNotifications = true;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<Transaction>('transactions');
    _refreshMonths();
    _loadPrefs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = prefs.getString('amount') ?? '';
    //print('🎯 Loaded target amount: $loaded'); // Debug
    setState(() {
      _targetAmount = loaded;
      //_homeNotifications = prefs.getBool('homeNotifications') ?? true;
    });
  }

  void _refreshMonths() {
    final transactions = _box.values.toList();
    _recentMonths = _getRecentMonths(transactions);
    _selectedMonthYear = _recentMonths.isNotEmpty
        ? _recentMonths.first
        : MonthYear(year: DateTime.now().year, month: DateTime.now().month);
  }

  List<MonthYear> _getRecentMonths(List<Transaction> transactions) {
    final Set<String> keys = {};
    final List<MonthYear> result = [];

    for (var tx in transactions) {
      if (tx.transactionType == 'Expense') {
        final key = '${tx.year}-${tx.month.toString().padLeft(2, '0')}';
        if (keys.add(key)) {
          result.add(MonthYear(year: tx.year, month: tx.month));
        }
      }
    }

    result.sort(
      (a, b) => DateTime(b.year, b.month).compareTo(DateTime(a.year, a.month)),
    );
    return result.take(5).toList();
  }

  String _formatMonthYear(MonthYear m) {
    final date = DateTime(m.year, m.month);
    return DateFormat('MMMM yyyy').format(date);
  }

  double _calculateBalance(List<Transaction> transactions) =>
      transactions.fold(0.0, (sum, tx) => sum + tx.amount);

  double _calculateUsableBalance(List<Transaction> transactions) =>
      transactions.fold(0.0, (sum, tx) => sum + tx.usablePortion);

  double _calculateCpfBalance(List<Transaction> transactions) =>
      transactions.fold(0.0, (sum, tx) => sum + tx.cpfPortion);

  double getThisMonthUsableIncome(int year, int month) {
    final txs = _box.values.toList();
    return txs
        .where(
          (tx) =>
              tx.transactionType == 'Income' &&
              tx.year == year &&
              tx.month == month,
        )
        .fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getThisMonthIncome(int year, int month) {
    final transactions = _box.values.toList();
    return transactions
        .where(
          (tx) =>
              tx.transactionType == 'Income' &&
              tx.year == year &&
              tx.month == month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<Transaction> box, _) {
          final allTx = box.values.toList();

          // Refresh recentMonths in case of new data
          final updated = _getRecentMonths(allTx);
          if (!updated.contains(_selectedMonthYear) && updated.isNotEmpty) {
            _selectedMonthYear = updated.first;
          }
          _recentMonths = updated;

          final filteredTx = allTx
              .where(
                (tx) =>
                    tx.year == _selectedMonthYear.year &&
                    tx.month == _selectedMonthYear.month,
              )
              .toList();

          final balance = _calculateBalance(allTx);
          final usable = _calculateUsableBalance(allTx);
          final cpf = _calculateCpfBalance(allTx);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'SAVEWISER',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildBalanceCard(balance, usable, cpf),
                  const SizedBox(height: 24),

                  // Month dropdown
                  _buildMonthDropdown(),

                  const SizedBox(height: 24),

                  SavingsPieChart(
                    transactions: filteredTx,
                    targetSavingsPercent: 20.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionListPage(
                            transactions: filteredTx
                                .map(
                                  (tx) => {
                                    "description": tx.description ?? '',
                                    "amount": tx.amount,
                                    "category": tx.category,
                                    "date": DateTime(
                                      tx.year,
                                      tx.month,
                                      tx.date!,
                                    ),
                                  },
                                )
                                .toList(),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionListPage(
                              transactions: filteredTx
                                  .map(
                                    (tx) => {
                                      "description": tx.description ?? '',
                                      "amount": tx.amount,
                                      "category": tx.category,
                                      "date": DateTime(
                                        tx.year,
                                        tx.month,
                                        tx.date!,
                                      ),
                                    },
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text("See Transaction History"),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSavingsCard(allTx),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpendingTrackerPage()),
          ).then((_) {
            setState(() => _refreshMonths());
          });
        },
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double usable, double cpf) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final today = now.day;
    final remainingDays = daysInMonth - today + 1; // include today

    // Calculate today's total spending
    final double spentToday = _box.values
        .where(
          (tx) =>
              tx.transactionType == 'Expense' &&
              tx.year == now.year &&
              tx.month == now.month &&
              tx.date == now.day,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    // Calculate today's adjusted spending limit
    final double totalUsableIncome = getThisMonthUsableIncome(
      now.year,
      now.month,
    );

    // Calculate usable already spent BEFORE today
    final double spentBeforeToday = _box.values
        .where(
          (tx) =>
              tx.transactionType == 'Expense' &&
              tx.year == now.year &&
              tx.month == now.month &&
              tx.date != null &&
              tx.date! < now.day,
        )
        .fold(0.0, (sum, tx) => sum + tx.usablePortion.abs());

    final double remainingUsable = totalUsableIncome - spentBeforeToday;

    final double rawLimit = (remainingUsable > 0 && remainingDays > 0)
        ? remainingUsable / remainingDays
        : 0.0;
    final double adjustedTodayLimit = rawLimit - spentToday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildBalanceRow("Total Balance", balance, Colors.blue.shade800),
          _buildBalanceRow("Usable Balance", usable, Colors.green.shade700),
          _buildBalanceRow("CPF Balance", cpf, Colors.orange.shade700),
          const SizedBox(height: 12),

          // Today's spending limit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  "Today's Spending Limit",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${currencyFormatter.format(adjustedTodayLimit.clamp(0, double.infinity))} IDR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: adjustedTodayLimit >= 0 ? Colors.teal : Colors.red,
                ),
              ),
            ],
          ),

          if (getThisMonthIncome(now.year, now.month) <= 0)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "⚠️ You haven't added income for this month.\nDaily spending limit is inactive.",
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
            )
          else if (adjustedTodayLimit < 0)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "⚠️ You've exceeded today's limit.",
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MonthYear>(
          value: _selectedMonthYear,
          isExpanded: true,
          items: _recentMonths.map((monthYear) {
            return DropdownMenuItem(
              value: monthYear,
              child: Text(
                _formatMonthYear(monthYear),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _buildBalanceRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '${currencyFormatter.format(value)} IDR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(List<Transaction> allTransactions) {
    final totalSavings = allTransactions
        .where(
          (tx) => tx.transactionType == 'Expense' && tx.category == 'Savings',
        )
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saved (All Time)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${currencyFormatter.format(totalSavings)} IDR',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "Savings Goal: ",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                _targetAmount.isNotEmpty
                    ? '${currencyFormatter.format(double.tryParse(_targetAmount.replaceAll(',', '')) ?? 0)} IDR'
                    : 'Not Set',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SavingsPieChart extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback onTap;
  final double targetSavingsPercent;

  const SavingsPieChart({
    super.key,
    required this.transactions,
    required this.onTap,
    required this.targetSavingsPercent,
  });

  String _generateFeedback(Map<String, double> categoryTotals) {
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return "No spending data for this month.";

    final savingsPct = (categoryTotals['Savings'] ?? 0) / total * 100;
    final wantsPct = (categoryTotals['Wants'] ?? 0) / total * 100;
    final needsPct = (categoryTotals['Needs'] ?? 0) / total * 100;

    final feedback = <String>[];

    if (savingsPct >= targetSavingsPercent + 5) {
      feedback.add("🎉 You saved more than your goal. Amazing!");
    } else if (savingsPct >= targetSavingsPercent) {
      feedback.add("✅ You hit your savings target!");
    } else {
      feedback.add("🚨 Savings below target. Try spending less on wants.");
    }

    if (wantsPct > 30) {
      feedback.add("⚠️ Wants exceeded 30%. Try reducing non-essentials.");
    }

    if (needsPct > 50) {
      feedback.add("📊 Needs took over 50%. Can anything be optimized?");
    }

    return feedback.join("\n");
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = {
      "Needs": 0.0,
      "Wants": 0.0,
      "Savings": 0.0,
    };
    for (final tx in transactions) {
      if (tx.transactionType != 'Expense') continue;

      if (categoryTotals.containsKey(tx.category)) {
        categoryTotals[tx.category] =
            (categoryTotals[tx.category] ?? 0) + tx.amount.abs();
      }
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return const Center(child: Text("No expense data available"));
    }

    final Map<String, double> dataMap = {
      for (var entry in categoryTotals.entries) entry.key: entry.value,
    };

    final colorList = [Colors.blue, Colors.red.shade700, Colors.green.shade700];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartType: ChartType.disc,
            chartRadius: MediaQuery.of(context).size.width * 0.45,
            colorList: colorList,
            chartValuesOptions: const ChartValuesOptions(
              showChartValuesInPercentage: true,
              showChartValueBackground: false,
              chartValueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            legendOptions: const LegendOptions(showLegends: false),
          ),
          const SizedBox(height: 20),

          // Custom Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: categoryTotals.keys.toList().asMap().entries.map((entry) {
              int index = entry.key;
              String key = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: colorList[index], size: 14),
                    const SizedBox(width: 6),
                    Text(key, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Feedback Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: Colors.indigo[50],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _generateFeedback(categoryTotals),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.indigo,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
