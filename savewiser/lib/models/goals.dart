import 'package:hive/hive.dart';

part 'goals.g.dart';

@HiveType(typeId: 1)
class Goal extends HiveObject {
  @HiveField(0)
  final double targetAmount;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final DateTime? targetDate;

  @HiveField(3)
  final double initialSavings;

  @HiveField(4)
  final String purpose;

  Goal({
    required this.targetAmount,
    required this.createdAt,
    this.targetDate,
    required this.initialSavings,
    required this.purpose,
  });
}
