import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CurrentSavingsPage extends StatefulWidget {
  const CurrentSavingsPage({super.key});

  @override
  CurrentSavingsPageState createState() => CurrentSavingsPageState();
}

class CurrentSavingsPageState extends State<CurrentSavingsPage> {
  late SharedPreferences prefs;
  Map<String, dynamic> savingsData = {
    "savings": 30,
    "wants": 25,
    "needs": 45,
    "details": [
      {
        "date": "2025-01-31",
        "description": "Electricity Bill",
        "amount": -50000,
        "category": "needs",
      },
      {
        "date": "2025-01-31",
        "description": "Pizza",
        "amount": -18000,
        "category": "wants",
      },
      {
        "date": "2025-01-31",
        "description": "Salary",
        "amount": 6000000,
        "category": "income",
      },
      {
        "date": "2025-01-31",
        "description": "Lunch at work",
        "amount": -20000,
        "category": "needs",
      },
      {
        "date": "2025-01-30",
        "description": "Petrol",
        "amount": -30000,
        "category": "needs",
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSavingsData();
  }

  Future<void> _loadSavingsData() async {
    prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('savingsData');
    if (savedData != null) {
      setState(() {
        savingsData = json.decode(savedData);
      });
    } else {
      await prefs.setString('savingsData', json.encode(savingsData));
    }
  }

  Future<void> _updateSavingsData() async {
    await prefs.setString('savingsData', json.encode(savingsData));
  }

  void _showDetailsDialog(String category) {
    List<Map<String, dynamic>> filteredDetails = savingsData['details']
        .where((item) => item['category'] == category)
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: filteredDetails.length,
          itemBuilder: (context, index) {
            var detail = filteredDetails[index];
            return ListTile(
              title: Text(detail['description']),
              subtitle: Text(detail['date']),
              trailing: Text(
                '${detail['amount'] > 0 ? '+' : ''}Rp ${detail['amount'].toString()}',
                style: TextStyle(
                  color: detail['amount'] > 0 ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Savings')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.3,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: savingsData['needs'].toDouble(),
                    title: '${savingsData['needs']}%',
                    color: Colors.blue,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    badgeWidget: GestureDetector(
                      onTap: () => _showDetailsDialog("needs"),
                      child: Icon(
                        Icons.touch_app,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  PieChartSectionData(
                    value: savingsData['wants'].toDouble(),
                    title: '${savingsData['wants']}%',
                    color: Colors.red,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    badgeWidget: GestureDetector(
                      onTap: () => _showDetailsDialog("wants"),
                      child: Icon(
                        Icons.touch_app,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  PieChartSectionData(
                    value: savingsData['savings'].toDouble(),
                    title: '${savingsData['savings']}%',
                    color: Colors.green,
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    badgeWidget: GestureDetector(
                      onTap: () => _showDetailsDialog("savings"),
                      child: Icon(
                        Icons.touch_app,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _updateSavingsData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Savings data updated successfully!"),
                ),
              );
            },
            child: const Text("Save Today's Data"),
          ),
        ],
      ),
    );
  }
}
