import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:savewiser/pages/profile_page.dart';
import 'package:savewiser/main_nav.dart';

class CurrentSavingsPage extends StatelessWidget {
  const CurrentSavingsPage({super.key});

  static final List<Map<String, dynamic>> transactions = [
    {
      "description": "Electricity Bill",
      "amount": -50000,
      "category": "Needs",
      "date": DateTime(2023, 1, 4),
    },
    {
      "description": "Pizza",
      "amount": -18000,
      "category": "Wants",
      "date": DateTime(2023, 1, 4),
    },
    {
      "description": "Salary",
      "amount": 6000000,
      "category": "Income",
      "date": DateTime(2023, 1, 2),
    },
    {
      "description": "Lunch at work",
      "amount": -20000,
      "category": "Needs",
      "date": DateTime(2023, 1, 2),
    },
    {
      "description": "Petrol",
      "amount": -30000,
      "category": "Needs",
      "date": DateTime(2023, 1, 1),
    },
    {
      "description": "Vacation Fund",
      "amount": -100000,
      "category": "Savings",
      "date": DateTime(2023, 1, 5),
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TransactionListPage(transactions: transactions),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsPieChart extends StatelessWidget {
  final VoidCallback onTap;

  const SavingsPieChart({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final dataMap = {"Needs": 45.0, "Wants": 25.0, "Savings": 30.0};
    final colors = [Colors.blue, Colors.red.shade700, Colors.green.shade700];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 250,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 0,
            pieTouchData: PieTouchData(enabled: false),
            sections: List.generate(dataMap.length, (index) {
              final category = dataMap.keys.elementAt(index);
              final value = dataMap[category]!;
              return PieChartSectionData(
                color: colors[index],
                value: value,
                title: "${value.toStringAsFixed(1)}%",
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class TransactionListPage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionListPage({super.key, required this.transactions});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'Date';

  List<Map<String, dynamic>> get filtered {
    List<Map<String, dynamic>> txs = widget.transactions;

    if (selectedCategory != 'All') {
      txs = txs.where((tx) => tx['category'] == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      txs = txs
          .where(
            (tx) => tx['description'].toLowerCase().contains(
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
                    color: Color(0xFF1A237E), // same as Colors.indigo[900]
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Fixed index for "Savings"
        selectedItemColor: Colors.blue,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Future Statistics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Savings'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Plannings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
