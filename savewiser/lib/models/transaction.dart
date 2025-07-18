// import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String category; // Needs, Wants, Savings

  @HiveField(1)
  double amount;

  @HiveField(2)
  int month;

  @HiveField(3)
  int year;

  @HiveField(4)
  int? date;

  @HiveField(5)
  String? transactionType; // income or expense

  @HiveField(6)
  String? description; // Details about the transaction

  @HiveField(7)
  String? currency; // Currency type

  @HiveField(8)
  double cpfPortion;

  @HiveField(9)
  double usablePortion;

  Transaction({
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
    required this.date,
    required this.transactionType,
    required this.description,
    required this.currency,
    required this.cpfPortion,
    required this.usablePortion,
  });
}
