import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

Future<void> recalculateSavingsBaseline(Box<Transaction> box) async {
  final allTx = box.values.toList();
  final prefs = await SharedPreferences.getInstance();

  final rawSavings = allTx
      .where(
        (tx) => tx.transactionType == 'Expense' && tx.category == 'Savings',
      )
      .fold(0.0, (sum, tx) => sum + tx.amount.abs());

  await prefs.setDouble('savingsBaseline', rawSavings);
}
