import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.decimalPattern();

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _name = "";
  Map<String, double> _categoryTotals = {"Needs": 0, "Wants": 0, "Savings": 0};
  String _statusLabel = "Loading...";
  Color _statusColor = Colors.grey;
  List<Transaction> _recentExpenses = [];

  @override
  void initState() {
    super.initState();
    initShared();
    _loadHiveData();
  }

  Future<void> initShared() async {
    final prefs = await SharedPreferences.getInstance();
    _name = prefs.getString("name") ?? "";
    setState(() {});
  }

  Future<void> _loadHiveData() async {
    final box = Hive.box<Transaction>('transactions');
    final now = DateTime.now();
    final currentMonthTxs = box.values.where(
      (tx) =>
          tx.transactionType == 'Expense' &&
          tx.year == now.year &&
          tx.month == now.month,
    );

    final Map<String, double> totals = {
      "Needs": 0.0,
      "Wants": 0.0,
      "Savings": 0.0,
    };

    for (var tx in currentMonthTxs) {
      if (totals.containsKey(tx.category)) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount.abs();
      }
    }

    final double totalSpending = totals.values.fold(0.0, (a, b) => a + b);

    final Map<String, double> percentages = {
      for (var entry in totals.entries)
        entry.key: totalSpending == 0 ? 0 : (entry.value / totalSpending) * 100,
    };

    final bool isOnTrack =
        _isWithinMargin(percentages["Needs"]!, 50) &&
        _isWithinMargin(percentages["Wants"]!, 30) &&
        _isWithinMargin(percentages["Savings"]!, 20);

    final recent = currentMonthTxs.toList()
      ..sort((a, b) {
        final aDate = DateTime(a.year, a.month, a.date ?? 1);
        final bDate = DateTime(b.year, b.month, b.date ?? 1);
        return aDate.compareTo(bDate); // oldest first
      });

    final lastThree = recent.length >= 3
        ? recent.sublist(recent.length - 3)
        : recent;

    setState(() {
      _categoryTotals = totals;
      _statusLabel = isOnTrack ? "On Track" : "Off Track";
      _statusColor = isOnTrack ? Colors.green : Colors.red;
      _recentExpenses = lastThree.reversed.toList(); // newest at the top
    });
  }

  bool _isWithinMargin(double value, double target) {
    return (value >= target - 5) && (value <= target + 5);
  }

  Widget legendItem(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget buildSavingsPieChartCard() {
    final Map<String, double> dataMap = {
      for (var entry in _categoryTotals.entries) entry.key: entry.value,
    };

    final List<Color> colorList = [
      Colors.blue, // Needs
      Colors.red.shade700, // Wants
      Colors.green.shade700, // Savings
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final double chartSize = screenWidth * 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Savings this Month",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: chartSize,
                width: chartSize,
                child: PieChart(
                  dataMap: dataMap,
                  animationDuration: const Duration(milliseconds: 800),
                  chartType: ChartType.disc,
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    legendItem("Needs", Colors.blue),
                    legendItem("Wants", Colors.red.shade700),
                    legendItem("Savings", Colors.green.shade700),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                _statusLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecentSpendingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Spending',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._recentExpenses.map((tx) {
            final categoryColor =
                {
                  'Needs': Colors.blue[300],
                  'Wants': Colors.red[300],
                  'Savings': Colors.green[300],
                }[tx.category] ??
                Colors.grey;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: categoryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tx.category}: ${tx.currency} ${currencyFormatter.format(tx.amount)} at ${tx.description ?? "Unknown"}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'SAVEWISER',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Welcome Back $_name (SW107788)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            buildSavingsPieChartCard(),
            const SizedBox(height: 24),
            buildRecentSpendingCard(),
          ],
        ),
      ),
    );
  }
}
