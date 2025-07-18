import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/thousand_separator_input.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../main_nav.dart';

final NumberFormat currencyFormatter = NumberFormat.decimalPattern()
  ..maximumFractionDigits = 0; // 'en_US' by default

class SpendingTrackerPage extends StatefulWidget {
  final bool fromSetup;
  const SpendingTrackerPage({super.key, this.fromSetup = false});

  @override
  State<SpendingTrackerPage> createState() => _SpendingTrackerPageState();
}

class _SpendingTrackerPageState extends State<SpendingTrackerPage> {
  late Box<Transaction> _box;
  bool _isBoxReady = false;
  int _autoLockPct = 10; // default to 10%
  bool _guardEnable = false;
  bool _homeNotifications = true;

  @override
  void initState() {
    super.initState();
    _openBox();
    _loadPrefs();
    _amountController.addListener(() {
      setState(() {}); // Triggers rebuild on every input change
    });
  }

  Future<void> _openBox() async {
    _box = await Hive.openBox<Transaction>('transactions');
    setState(() {
      _isBoxReady = true;
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _guardEnable = prefs.getBool('guardianEnabled') ?? false;
    _homeNotifications = prefs.getBool('homeNotifications') ?? true;
    if (_guardEnable) {
      _autoLockPct = prefs.getInt('autoLockPct') ?? 0;
    } else {
      _autoLockPct = 0;
    }
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

  double getTotalBalanceUntil(DateTime selectedDate) {
    final txs = _box.values.where((tx) => tx.date != null).toList();

    return txs
        .where((tx) {
          final txDate = DateTime(tx.year, tx.month, tx.date!);
          return txDate.isBefore(selectedDate.add(const Duration(days: 1)));
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getUsableBalance() {
    final transactions = _box.values.toList();
    return transactions.fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getUsableBalanceUntil(DateTime selectedDate) {
    final txs = _box.values.where((tx) => tx.date != null).toList();

    return txs
        .where((tx) {
          final txDate = DateTime(tx.year, tx.month, tx.date!);
          return txDate.isBefore(selectedDate.add(const Duration(days: 1)));
        })
        .fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getCpfBalance() {
    final transactions = _box.values.toList();
    return transactions.fold(0.0, (sum, tx) => sum + tx.cpfPortion);
  }

  double _getEstimatedCpf() {
    final input = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );
    return (input ?? 0.0) * (_autoLockPct / 100);
  }

  double _getEstimatedUsable() {
    final input = double.tryParse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );
    final cpf = (input ?? 0.0) * (_autoLockPct / 100);
    return (input ?? 0.0) - cpf;
  }

  double _getInputAmount() {
    return double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0.0;
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

  double getUsableIncome() {
    final txs = _box.values.toList();
    return txs
        .where((tx) => tx.transactionType == 'Income')
        .fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getSpendingOnDay(int year, int month, int day) {
    final transactions = _box.values.toList();
    return transactions
        .where(
          (tx) =>
              tx.transactionType == 'Expense' &&
              tx.year == year &&
              tx.month == month &&
              tx.date == day,
        )
        .fold(0.0, (sum, tx) => sum + tx.usablePortion.abs());
  }

  double getTotalOverspentUntilToday() {
    final now = DateTime.now();
    double dailyLimit =
        getThisMonthIncome(now.year, now.month) /
        DateUtils.getDaysInMonth(now.year, now.month);

    double totalOverspent = 0.0;

    for (int d = 1; d <= now.day; d++) {
      double spent = getSpendingOnDay(now.year, now.month, d);
      if (spent > dailyLimit) {
        totalOverspent += (spent - dailyLimit);
      }
    }

    return totalOverspent;
  }

  double getAdjustedTodayLimit() {
    final now = DateTime.now();
    final totalUsableIncome = getUsableIncome();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    final today = DateTime.now();

    final spentBeforeToday = _box.values
        .where((tx) {
          if (tx.transactionType != 'Expense') return false;
          if (tx.date == null) return false;

          final txDate = DateTime(tx.year, tx.month, tx.date!);
          return txDate.isBefore(DateTime(today.year, today.month, today.day));
        })
        .fold(0.0, (sum, tx) => sum + tx.usablePortion.abs());

    final remainingUsable = totalUsableIncome - spentBeforeToday;
    final remainingDays = daysInMonth - now.day + 1;

    if (remainingUsable <= 0 || remainingDays <= 0) return 0.0;

    return remainingUsable / remainingDays;
  }

  DateTime? getFirstIncomeDate() {
    final incomes = _box.values
        .where((tx) => tx.transactionType == 'Income')
        .toList();
    if (incomes.isEmpty) return null;

    incomes.sort((a, b) {
      final aDate = DateTime(a.year, a.month, a.date ?? 1);
      final bDate = DateTime(b.year, b.month, b.date ?? 1);
      return aDate.compareTo(bDate);
    });

    return DateTime(
      incomes.first.year,
      incomes.first.month,
      incomes.first.date ?? 1,
    );
  }

  void _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedYear,
      _selectedMonth,
      _selectedDate,
    );

    if (selectedDateTime.isAfter(DateTime(now.year, now.month, now.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚫 You can't add a transaction for a future date."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double amount =
        double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0.0;

    final String description = _descriptionController.text;
    // final double balance = getCurrentBalance();
    // final double usableBalance = getUsableBalance();
    // final double cpfBalance = getCpfBalance();

    final firstIncomeDate = getFirstIncomeDate();
    final usableBalanceAtTime = getUsableBalanceUntil(selectedDateTime);
    final totalBalanceAtTime = getTotalBalanceUntil(selectedDateTime);

    if (_transactionType == 'Expense' &&
        firstIncomeDate != null &&
        selectedDateTime.isBefore(firstIncomeDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🚫 You can't add expenses before your first income on ${DateFormat('d MMM yyyy').format(firstIncomeDate)}.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_transactionType == 'Expense') {
      if (amount > totalBalanceAtTime) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Insufficient total balance (at this time) to make this expense.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (usableBalanceAtTime < amount) {
        double remainingAmount = amount - usableBalanceAtTime;
        bool cpfApproved = false;
        cpfApproved = await _promptForCpfApproval(remainingAmount);
        if (!cpfApproved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You need approval to use CPF funds."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        usablePortion = -usableBalanceAtTime.abs();
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

    if (_transactionType == 'Expense') {
      final now = DateTime.now();
      final todaySpent = getSpendingOnDay(now.year, now.month, now.day);
      final todayLimit = getAdjustedTodayLimit();
      final usableIncome = getUsableIncome();

      if (usableIncome > 0 && todaySpent > todayLimit) {
        if (_homeNotifications) {
          NotificationService().showNow(
            id: 1,
            title: "Overspending Alert!",
            body:
                "You've spent ${currencyFormatter.format(todaySpent)} from your usable balance today, which exceeds your limit of ${currencyFormatter.format(todayLimit)}.",
          );
        }
      }
    }

    // Clear the form fields
    _amountController.clear();
    _descriptionController.clear();

    // Go back to the previous screen
    if (context.mounted) {
      if (widget.fromSetup) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSetupDone', true);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainNavigation(initialIndex: 2),
          ),
          (route) => false,
        );
      } else {
        Navigator.pop(context); // Normal case
      }
    }
  }

  // Function to prompt for CPF approval
  Future<bool> _promptForCpfApproval(double remainingAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final guardianEnabled = prefs.getBool('guardianEnabled') ?? false;
    final storedPasscode = prefs.getString('guardianPasscode') ?? '';

    final approved =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Use CPF Funds'),
              content: Text(
                'Do you approve using ${currencyFormatter.format(remainingAmount)} $_currency from your CPF balance?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Approve'),
                ),
              ],
            );
          },
        ) ??
        false;

    // If user declined, or no guardian control needed, return result
    if (!approved || !guardianEnabled || storedPasscode.isEmpty)
      return approved;

    // Require passcode if guardian is active
    return await _verifyGuardianPasscodeDialog(storedPasscode);
  }

  Future<bool> _verifyGuardianPasscodeDialog(String correctPasscode) async {
    final TextEditingController passCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Guardian Approval Required'),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Enter Guardian Passcode',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, passCtrl.text.trim() == correctPasscode);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (result != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect or missing guardian passcode')),
      );
    }

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now(); // ✅ this was missing

    final double balance = getCurrentBalance();
    // final double cpfBalance = getCpfBalance();
    // final double usableBalance = getUsableBalance();

    double todaySpent = getSpendingOnDay(now.year, now.month, now.day);
    double todayLimit = getAdjustedTodayLimit();

    // Force "Income" type if balance is 0
    if (balance <= 0 && _transactionType != 'Income') {
      _transactionType = 'Income';
      _selectedCategory = 'Needs';
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Transaction Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _transactionType.isNotEmpty ? _transactionType : null,
                items: _transactionTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (balance <= 0)
                    ? null
                    : (val) => setState(() => _transactionType = val!),
                decoration: const InputDecoration(
                  labelText: "Transaction Type",
                ),
              ),

              if (balance <= 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "You must add income before recording expenses.",
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
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
                maxLength: 19,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(), // or 'en'
                ],
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
                maxLength: 50,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
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
                  "Guardian Control: ${_guardEnable ? 'ON' : 'OFF'} (Lock $_autoLockPct%)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  "Estimated Usable: ${currencyFormatter.format(_getEstimatedUsable())} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  "Estimated CPF Lock: ${currencyFormatter.format(_getEstimatedCpf())} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ] else if (_transactionType == 'Expense') ...[
                Text(
                  _transactionType == 'Expense' &&
                          _amountController.text.isNotEmpty
                      ? "After Transaction - Usable: ${currencyFormatter.format((getUsableBalance() - (_getInputAmount().clamp(0, getUsableBalance()))).toInt())} $_currency"
                      : "Current Usable Balance: ${currencyFormatter.format(getUsableBalance().toInt())} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  _transactionType == 'Expense' &&
                          _amountController.text.isNotEmpty &&
                          _getInputAmount() > getUsableBalance()
                      ? "After Transaction - CPF: ${currencyFormatter.format((getCpfBalance() - (_getInputAmount() - getUsableBalance())).toInt())} $_currency"
                      : "CPF Balance: ${currencyFormatter.format(getCpfBalance().toInt())} $_currency",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (getThisMonthIncome(now.year, now.month) <= 0)
                  const Text(
                    "⚠️ You haven't added any income for this month.\nDaily spending limit is disabled.",
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  )
                else if (todaySpent > todayLimit)
                  Text(
                    "⚠️ You’ve exceeded today’s adjusted limit by ${currencyFormatter.format(todaySpent - todayLimit)}",
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
              ],

              ElevatedButton(
                onPressed: _addTransaction,
                child: const Text("Add Transaction"),
              ),

              if (widget.fromSetup)
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(
                      'isSetupDone',
                      true,
                    ); // mark setup complete

                    if (!mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MainNavigation(initialIndex: 2),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Add Later",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
