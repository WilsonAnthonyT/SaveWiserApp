import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'spending_tracker.dart';

class CurrentSavingsPage extends StatefulWidget {
  const CurrentSavingsPage({super.key});

  @override
  State<CurrentSavingsPage> createState() => _CurrentSavingsPageState();
}

class _CurrentSavingsPageState extends State<CurrentSavingsPage> {
  String? selectedCategory;

  final List<Map<String, dynamic>> transactions = [
    {"description": "Electricity Bill", "amount": -50000, "category": "Needs"},
    {"description": "Pizza", "amount": -18000, "category": "Wants"},
    {"description": "Salary", "amount": 6000000, "category": "Income"},
    {"description": "Lunch at work", "amount": -20000, "category": "Needs"},
    {"description": "Petrol", "amount": -30000, "category": "Needs"},
    {"description": "Vacation Fund", "amount": -100000, "category": "Savings"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredTransactions = selectedCategory == null
        ? transactions
        : transactions
              .where((tx) => tx["category"] == selectedCategory)
              .toList();

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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "January 2023",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SavingsPieChart(
                    onSectionTapped: (category) {
                      if (!mounted) return;
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              selectedCategory == null
                  ? "All Transactions"
                  : "$selectedCategory Transactions",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...filteredTransactions.map((tx) {
              return _buildTransactionItem(
                tx["description"],
                tx["amount"],
                tx["category"],
              );
            }),
            if (selectedCategory != null)
              TextButton(
                onPressed: () {
                  if (!mounted) return;
                  setState(() => selectedCategory = null);
                },
                child: const Text("Show All"),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpendingTrackerPage()),
          );
        },
        backgroundColor: Colors.indigo[900],
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildTransactionItem(
    String description,
    int amount,
    String category,
  ) {
    return ListTile(
      leading: Icon(Icons.monetization_on, color: Colors.grey[700]),
      title: Text(description),
      subtitle: Text(category),
      trailing: Text(
        "${amount >= 0 ? "+" : "-"}\$${(amount.abs() / 1000).toStringAsFixed(1)}k",
        style: TextStyle(
          color: amount >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SavingsPieChart extends StatefulWidget {
  final Function(String category) onSectionTapped;

  const SavingsPieChart({required this.onSectionTapped, super.key});

  @override
  State<SavingsPieChart> createState() => _SavingsPieChartState();
}

class _SavingsPieChartState extends State<SavingsPieChart> {
  int? touchedIndex;

  final Map<String, double> dataMap = {"Needs": 45, "Wants": 25, "Savings": 30};

  final List<Color> colorList = [
    Colors.blue,
    Colors.red.shade700,
    Colors.green.shade700,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final chartSize = screenWidth * 0.8;

    return SizedBox(
      height: chartSize,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 0,
          pieTouchData: PieTouchData(
            mouseCursorResolver: (event, response) => SystemMouseCursors.basic,
            touchCallback: (event, pieTouchResponse) {
              if (!mounted ||
                  !event.isInterestedForInteractions ||
                  pieTouchResponse?.touchedSection == null) {
                return;
              }

              // Safely access the index of the touched section
              final index =
                  pieTouchResponse!.touchedSection!.touchedSectionIndex;

              // Check if the index is valid before accessing the data
              if (index >= 0 && index < dataMap.length) {
                final category = dataMap.keys.elementAt(index);
                setState(() => touchedIndex = index);
                widget.onSectionTapped(category);
              }
            },
          ),

          sections: List.generate(dataMap.length, (index) {
            final category = dataMap.keys.elementAt(index);
            final value = dataMap[category]!;
            final isTouched = index == touchedIndex;

            return PieChartSectionData(
              color: colorList[index],
              value: value,
              title: "${value.toStringAsFixed(1)}%",
              radius: isTouched ? 115 : 100,
              titleStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
    );
  }
}
