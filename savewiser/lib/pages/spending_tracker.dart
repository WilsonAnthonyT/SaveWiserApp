import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';

class SpendingTrackerPage extends StatefulWidget {
  const SpendingTrackerPage({super.key});

  @override
  State<SpendingTrackerPage> createState() => _SpendingTrackerPageState();
}

class _SpendingTrackerPageState extends State<SpendingTrackerPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Needs';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _categories = ['Needs', 'Wants', 'Savings'];

  void _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text);

    final tx = Transaction(
      category: _selectedCategory,
      amount: amount,
      month: _selectedMonth,
      year: _selectedYear,
    );

    final box = Hive.box<Transaction>('transactions');
    await box.add(tx);

    _amountController.clear();
    setState(() {}); // refresh chart
  }

  Map<String, double> _getSummary() {
    final box = Hive.box<Transaction>('transactions');
    final txs = box.values.where(
      (tx) => tx.month == _selectedMonth && tx.year == _selectedYear,
    );

    final summary = {'Needs': 0.0, 'Wants': 0.0, 'Savings': 0.0};
    for (var tx in txs) {
      summary[tx.category] = (summary[tx.category] ?? 0) + tx.amount;
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getSummary();
    final total = summary.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: const Text("Spending Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month and Year Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text("${i + 1}".padLeft(2, '0')),
                      ),
                    ),
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                    decoration: const InputDecoration(labelText: 'Month'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    items: List.generate(5, (i) => DateTime.now().year - i)
                        .map(
                          (y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedYear = val!),
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pie Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 0, // full pie (not donut)
                  sections: summary.entries.map((e) {
                    final percent = total == 0 ? 0.0 : (e.value / total) * 100;
                    return PieChartSectionData(
                      value: e.value,
                      title: '${e.key}\n${percent.toStringAsFixed(1)}%',
                      color: e.key == 'Needs'
                          ? Colors.blue
                          : e.key == 'Wants'
                          ? Colors.orange
                          : Colors.green,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Add Transaction Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: "Amount"),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter an amount' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addTransaction,
                    child: const Text("Add Transaction"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
