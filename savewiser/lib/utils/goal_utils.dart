import 'package:hive/hive.dart';
import '../models/transaction.dart';
import '../models/goals.dart';

Future<void> createGoal(
  double amount,
  DateTime? targetDate,
  String purpose,
) async {
  final txBox = Hive.box<Transaction>('transactions');
  final initialSavings = txBox.values
      .where(
        (tx) => tx.transactionType == 'Expense' && tx.category == 'Savings',
      )
      .fold(0.0, (sum, tx) => sum + tx.amount.abs());

  final goalBox = Hive.box<Goal>('goals');
  await goalBox.clear(); // We only track one goal at a time
  await goalBox.add(
    Goal(
      targetAmount: amount,
      createdAt: DateTime.now(),
      targetDate: targetDate,
      initialSavings: initialSavings,
      purpose: purpose,
    ),
  );
}
