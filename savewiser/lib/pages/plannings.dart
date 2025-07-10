import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart' as HiveTransaction;
import 'spending_tracker.dart';

typedef Category = String;

class Transaction {
  final String name;
  final Category category;
  final double amount;
  final DateTime timestamp;

  Transaction({
    required this.name,
    required this.category,
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'amount': amount,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      name: json['name'],
      category: json['category'],
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class PlanningsPage extends StatefulWidget {
  const PlanningsPage({Key? key}) : super(key: key);

  @override
  _PlanningsPageState createState() => _PlanningsPageState();
}

class _PlanningsPageState extends State<PlanningsPage> {
  final List<Transaction> _transactions = [];
  String _filter = 'All';
  late SharedPreferences _prefs;
  static const _storageKey = 'daily_planner_transactions';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    _prefs = await SharedPreferences.getInstance();
    final String? data = _prefs.getString(_storageKey);

    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      final today = DateTime.now();

      final todayOnly = list
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .where(
            (tx) =>
                tx.timestamp.year == today.year &&
                tx.timestamp.month == today.month &&
                tx.timestamp.day == today.day,
          )
          .toList();

      setState(() {
        _transactions
          ..clear()
          ..addAll(todayOnly);
      });
    }
  }

  Future<void> _saveTransactions() async {
    final today = DateTime.now();
    final todayOnly = _transactions
        .where(
          (tx) =>
              tx.timestamp.year == today.year &&
              tx.timestamp.month == today.month &&
              tx.timestamp.day == today.day,
        )
        .toList();

    final String data = jsonEncode(todayOnly.map((t) => t.toJson()).toList());
    await _prefs.setString(_storageKey, data);
  }

  Future<void> _completeTransaction(int index) async {
    final localTx = _transactions[index];
    final box = Hive.box<HiveTransaction.Transaction>('transactions');

    final isSpending = localTx.amount < 0;

    double cpfPortion = 0.0;
    double usablePortion = 0.0;

    if (isSpending) {
      final balance = getCurrentBalance(box);
      final usableBalance = getUsableBalance(box);
      final cpfBalance = getCpfBalance(box);
      final spendingAmount = localTx.amount.abs();

      if (spendingAmount > balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "🚫 Your total balance is insufficient for this plan.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (usableBalance < spendingAmount) {
        double cpfNeeded = spendingAmount - usableBalance;

        bool approved = await _promptForCpfApproval(cpfNeeded);
        if (!approved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🛑 Guardian approval required to use CPF."),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        usablePortion = -usableBalance.abs();
        cpfPortion = -cpfNeeded.abs();
      } else {
        usablePortion = -spendingAmount;
        cpfPortion = 0.0;
      }
    } else {
      // Income
      final prefs = await SharedPreferences.getInstance();
      final guardianEnabled = prefs.getBool('guardianEnabled') ?? false;
      final autoLockPct = guardianEnabled
          ? prefs.getInt('autoLockPct') ?? 0
          : 0;

      cpfPortion = localTx.amount * autoLockPct / 100.0;
      usablePortion = localTx.amount - cpfPortion;
    }

    // Save to Hive
    await box.add(
      HiveTransaction.Transaction(
        category: localTx.category,
        amount: localTx.amount,
        month: localTx.timestamp.month,
        year: localTx.timestamp.year,
        date: localTx.timestamp.day,
        transactionType: localTx.amount > 0 ? 'Income' : 'Expense',
        description: localTx.name,
        currency: 'IDR',
        cpfPortion: cpfPortion,
        usablePortion: usablePortion,
      ),
    );

    setState(() => _transactions.removeAt(index));
    await _saveTransactions();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('“${localTx.name}” moved to Transaction History'),
        ),
      );
    }
  }

  double getCurrentBalance(Box<HiveTransaction.Transaction> box) {
    return box.values.fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getUsableBalance(Box<HiveTransaction.Transaction> box) {
    return box.values.fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getCpfBalance(Box<HiveTransaction.Transaction> box) {
    return box.values.fold(0.0, (sum, tx) => sum + tx.cpfPortion);
  }

  Future<bool> _promptForCpfApproval(double remainingAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final guardianEnabled = prefs.getBool('guardianEnabled') ?? false;
    final storedPasscode = prefs.getString('guardianPasscode') ?? '';

    final approved =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Use CPF Funds'),
            content: Text(
              'Do you approve using ${NumberFormat.currency(locale: 'id_ID').format(remainingAmount)} from CPF savings?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Approve'),
              ),
            ],
          ),
        ) ??
        false;

    if (!approved || !guardianEnabled || storedPasscode.isEmpty)
      return approved;

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

  double getThisMonthUsableIncome(
    Box<HiveTransaction.Transaction> box,
    int year,
    int month,
  ) {
    return box.values
        .where(
          (tx) =>
              tx.transactionType == 'Income' &&
              tx.year == year &&
              tx.month == month,
        )
        .fold(0.0, (sum, tx) => sum + tx.usablePortion);
  }

  double getSpendingOnDay(
    Box<HiveTransaction.Transaction> box,
    int year,
    int month,
    int day,
  ) {
    return box.values
        .where(
          (tx) =>
              tx.transactionType == 'Expense' &&
              tx.year == year &&
              tx.month == month &&
              tx.date == day,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  double getAdjustedTodayLimit(Box<HiveTransaction.Transaction> box) {
    final now = DateTime.now();
    final totalUsableIncome = getThisMonthUsableIncome(
      box,
      now.year,
      now.month,
    );
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    final spentBeforeToday = box.values
        .where(
          (tx) =>
              tx.transactionType == 'Expense' &&
              tx.year == now.year &&
              tx.month == now.month &&
              tx.date != null &&
              tx.date! < now.day,
        )
        .fold(0.0, (sum, tx) => sum + tx.usablePortion.abs());

    final remainingUsable = totalUsableIncome - spentBeforeToday;
    final remainingDays = daysInMonth - now.day + 1;

    if (remainingUsable <= 0 || remainingDays <= 0) return 0.0;

    return remainingUsable / remainingDays;
  }

  void _addTransaction() {
    String name = '';
    String amountText = '';
    String selectedCategory = 'Needs';
    final amountController = TextEditingController();
    final formatter = NumberFormat.decimalPattern('en_US');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
                maxLength: 50,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 19,
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                onChanged: (val) {
                  final numeric = val.replaceAll(',', '');
                  if (numeric.isEmpty) return;
                  final parsed = int.parse(numeric);
                  final newText = formatter.format(parsed);
                  setModalState(() {
                    amountController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: newText.length,
                      ),
                    );
                  });
                  amountText = numeric;
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Needs', 'Wants'].map((cat) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: selectedCategory == cat,
                      onSelected: (_) =>
                          setModalState(() => selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountText) ?? 0;
                if (name.isNotEmpty && amount != 0) {
                  setState(() {
                    _transactions.add(
                      Transaction(
                        name: name,
                        category: selectedCategory.toLowerCase(),
                        amount: -amount,
                        // selectedCategory.toLowerCase() == 'needs'
                        //     ? -amount
                        //     : amount,
                        timestamp: DateTime.now(),
                      ),
                    );
                  });
                  _saveTransactions();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todaysTransactions = _transactions.where((t) {
      return t.timestamp.year == today.year &&
          t.timestamp.month == today.month &&
          t.timestamp.day == today.day;
    }).toList();

    final totalSpent = todaysTransactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = todaysTransactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
    final net = totalIncome + totalSpent;

    final filtered = _filter == 'All'
        ? todaysTransactions
        : todaysTransactions
              .where((t) => t.category.toLowerCase() == _filter.toLowerCase())
              .toList();

    final box = Hive.box<HiveTransaction.Transaction>('transactions');
    final now = DateTime.now();
    final usableIncome = getThisMonthUsableIncome(box, now.year, now.month);
    final todaySpent = getSpendingOnDay(box, now.year, now.month, now.day);
    final todayLimit = getAdjustedTodayLimit(box);
    final isOverspent = usableIncome > 0 && todaySpent > todayLimit;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Plannings'), centerTitle: true),
      body: Column(
        children: [
          // Summary metrics
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Center(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center text horizontally
                children: [
                  const Text(
                    'Remaining Planned Spending:',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center, // Just in case
                  ),
                  Text(
                    NumberFormat.simpleCurrency(
                      locale: 'id_ID',
                    ).format(totalSpent),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Filters
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Needs', 'Wants']
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          if (isOverspent)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "⚠️ You’ve spent ${currencyFormatter.format(todaySpent)} today, which exceeds your limit of ${currencyFormatter.format(todayLimit)}.",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Plan list with checklist
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No plans for today.'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final tx = filtered[i];
                      return ListTile(
                        title: Text(tx.name),
                        subtitle: Text(
                          DateFormat('hh:mm a').format(tx.timestamp),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              NumberFormat.simpleCurrency(
                                locale: 'id_ID',
                              ).format(tx.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.amount > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () => _completeTransaction(i),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                setState(() => _transactions.removeAt(i));
                                await _saveTransactions();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}
