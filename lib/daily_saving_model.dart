// lib/daily_saving_model.dart

class DailySavingModel {
  final DateTime date;
  final double amount;
  bool isCompleted;

  DailySavingModel({
    required this.date,
    required this.amount,
    this.isCompleted = false,
  });
}
