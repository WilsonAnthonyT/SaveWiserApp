import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpendingTrackerPage extends StatefulWidget {
  const SpendingTrackerPage({super.key});

  @override
  State<SpendingTrackerPage> createState() => _SpendingTrackerPageState();
}

class _SpendingTrackerPageState extends State<SpendingTrackerPage> {
  late Box<Transaction> _box;
  bool _isBoxReady = false;
  int _autoLockPct = 10; // default to 10%

  @override
  void initState() {
    super.initState();
    _openBox();
    _loadPrefs();
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox<Transaction>('transactions');
    setState(() {
      _isBoxReady = true;
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _autoLockPct = prefs.getInt('autoLockPct') ?? 0;
  }

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Needs';
  int _selectedDate = DateTime.now().day;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _transactionType = 'Expense';
  final String _currency = 'IDR';

  final List<String> _categories = ['Needs', 'Wants', 'Savings'];
  final List<String> _transactionTypes = ['Expense', 'Income'];

  double cpfPortion = 0.0;
  double usablePortion = 0.0;

  double getCurrentBalance() {
    final transactions = _box.values.toList();
    return transactions.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getUsableBalance() {
    final transactions = _box.values.toList();
    return transactions.fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getCpfBalance() {
    final transactions = _box.values.toList();
    return transactions.fold(0.0, (sum, tx) => sum + tx.cpfPortion);
  }

  double _getEstimatedCpf() {
    final input = double.tryParse(_amountController.text) ?? 0.0;
    return input * (_autoLockPct / 100); // dynamic CPF
  }

  double _getEstimatedUsable() {
    final input = double.tryParse(_amountController.text) ?? 0.0;
    return input - _getEstimatedCpf();
  }

  void _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    double amount = double.parse(_amountController.text);
    final String description = _descriptionController.text;
    final double balance = getCurrentBalance();
    final double usableBalance = getUsableBalance();
    final double cpfBalance = getCpfBalance();

    if (_transactionType == 'Expense') {
      if (amount > balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Insufficient total balance to make this expense.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (usableBalance < amount) {
        double remainingAmount = amount - usableBalance;
        bool cpfApproved = false;
        cpfApproved = await _promptForCfpApproval(remainingAmount);
        if (!cpfApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You need approval to use CPF funds."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        usablePortion = -usableBalance.abs();
        cpfPortion = -remainingAmount.abs();
      } else {
        usablePortion = -amount.abs();
        cpfPortion = 0.0;
      }
      amount = -amount.abs();
    } else {
      // Income transaction
      amount = amount.abs();
      cpfPortion = amount * _autoLockPct / 100.0;
      usablePortion = amount - cpfPortion;
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
      cpfPortion: cpfPortion,
      usablePortion: usablePortion,
    );

    // Add transaction to the box (database)
    await _box.add(tx);

    // Clear the form fields
    _amountController.clear();
    _descriptionController.clear();

    // Go back to the previous screen
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  // Function to prompt for CPF approval
  Future<bool> _promptForCfpApproval(double remainingAmount) async {
    // You can implement your logic for asking user approval here
    // For simplicity, we return true as if the user approved the use of CPF funds

    // For example, a dialog could pop up to ask for confirmation:
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Use CPF Funds'),
              content: Text(
                'Do you approve using $remainingAmount $_currency from your CPF balance?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // User declined
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // User approved
                  },
                  child: const Text('Approve'),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if the dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double balance = getCurrentBalance();
    final double cpfBalance = getCpfBalance();
    final double usableBalance = getUsableBalance();

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
                value: _transactionType.isNotEmpty
                    ? _transactionType
                    : null, // Ensure value is valid
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description'; // Message to show if the field is empty
                  }
                  return null; // If validation passes, return null
                },
              ),
              const SizedBox(height: 20),

              if (_transactionType == 'Income') ...[
                Text(
                  "Estimated CPF Lock: ${_getEstimatedCpf().toStringAsFixed(2)} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Estimated Usable: ${_getEstimatedUsable().toStringAsFixed(2)} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ] else if (_transactionType == 'Expense') ...[
                Text(
                  "Current Usable Balance: ${usableBalance.toStringAsFixed(2)} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "CPF Balance: ${cpfBalance.toStringAsFixed(2)} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],

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
