import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

class SpendingTrackerPage extends StatefulWidget {
  const SpendingTrackerPage({super.key});

  @override
  State<SpendingTrackerPage> createState() => _SpendingTrackerPageState();
}

class _SpendingTrackerPageState extends State<SpendingTrackerPage> {
  late Box<Transaction> _box;
  bool _isBoxReady = false;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox<Transaction>('transactions');
    setState(() {
      _isBoxReady = true;
    });
  }

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Needs';
  int _selectedDate = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _transactionType = 'Expense';
  String _currency = 'IDR';

  final List<String> _categories = ['Needs', 'Wants', 'Savings'];
  final List<String> _transactionTypes = ['Expense', 'Income'];

  double getCurrentBalance() {
    final transactions = _box.values.toList();
    return transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  void _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    double amount = double.parse(_amountController.text);
    final String description = _descriptionController.text;
    final double balance = getCurrentBalance();

    if (_transactionType == 'Expense') {
      if (balance <= 0 || amount > balance.abs()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Insufficient balance to make this expense."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      amount = -amount.abs();
    } else {
      amount = amount.abs();
      _selectedCategory = 'Income'; // force 'Income' category for income
    }

    final tx = Transaction(
      category: _selectedCategory,
      amount: amount,
      month: _selectedMonth,
      year: _selectedYear,
      date: _selectedDate,
      transactionType: _transactionType,
      description: description,
      currency: _currency,
    );

    await _box.add(tx);

    _amountController.clear();
    _descriptionController.clear();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double balance = getCurrentBalance();

    // Force "Income" type if balance is 0
    if (balance == 0 && _transactionType != 'Income') {
      _transactionType = 'Income';
      _selectedCategory = 'Needs';
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spending Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _transactionType,
                items: _transactionTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (balance == 0)
                    ? null // disable if balance is zero
                    : (val) => setState(() => _transactionType = val!),
                decoration: const InputDecoration(
                  labelText: "Transaction Type",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDate,
                      items: List.generate(
                        31,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text((i + 1).toString().padLeft(2, '0')),
                        ),
                      ),
                      onChanged: (val) => setState(() => _selectedDate = val!),
                      decoration: const InputDecoration(labelText: 'Day'),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      items: List.generate(5, (i) => DateTime.now().year - i)
                          .map(
                            (y) =>
                                DropdownMenuItem(value: y, child: Text('$y')),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter an amount' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged:
                    (_transactionType == 'Expense' && getCurrentBalance() > 0)
                    ? (val) => setState(() => _selectedCategory = val!)
                    : null,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTransaction,
                child: const Text("Add Transaction"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
