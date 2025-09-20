import 'package:hive/hive.dart';

part 'finance_model.g.dart';

@HiveType(typeId: 1)
class FinanceModel extends HiveObject {
  @HiveField(0)
  String title; // e.g. "Salary", "Grocery", "Loan Payment"

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String type;
  // "income", "expense", "loan", "saving", "reminder", "goal"

  @HiveField(4)
  String category;
  // e.g. "Food", "Transport", "Salary", "Debt", "Health"

  @HiveField(5)
  bool isCompleted;
  // for reminders or goals (true = done, false = pending)

  @HiveField(6)
  DateTime? dueDate;
  // for reminders, loans, or goals

  @HiveField(7)
  String? notes;
  // optional description

  FinanceModel({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.isCompleted = false,
    this.dueDate,
    this.notes,
  });
}
