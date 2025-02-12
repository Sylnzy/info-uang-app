import 'package:hive/hive.dart';

part '../transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final DateTime date;
  @HiveField(3)
  final String type;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });
}
