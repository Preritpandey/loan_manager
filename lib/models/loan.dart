// models/loan.dart
import 'package:hive/hive.dart';
part 'loan.g.dart';

@HiveType(typeId: 0)
class Loan extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  int duration;
  @HiveField(3)
  double interestRate;
  @HiveField(4)
  String type;
  @HiveField(5)
  String jewelleryName;
  @HiveField(6)
  String serialNumber;
  @HiveField(7)
  String phone;
  @HiveField(8)
  String address;
  @HiveField(9)
  String description;
  @HiveField(10)
  double amountGiven;
  @HiveField(11)
  double amountReceived;

  Loan({
    required this.name,
    required this.date,
    required this.duration,
    required this.interestRate,
    required this.type,
    required this.jewelleryName,
    required this.serialNumber,
    required this.phone,
    required this.address,
    required this.description,
    required this.amountGiven,
    this.amountReceived = 0.0,
  });

  double get acquiredInterest {
    // Full interest is calculated immediately when loan is given
    final fullInterest = (amountGiven * interestRate) / 100 * duration;
    return fullInterest;
  }

  double get compoundInterest {
    // Full interest is calculated immediately when loan is given
    final fullInterest = (amountGiven * interestRate) / 100 * duration;

    // If overdue, add additional interest on the total due amount
    if (isOverdue) {
      final totalDueAtDueDate = amountGiven + fullInterest;
      final overdueDays = this.overdueDays;
      final overdueInterestPerDay = (totalDueAtDueDate * interestRate) / 100;
      final overdueInterest = overdueInterestPerDay * overdueDays;
      return fullInterest + overdueInterest;
    }

    return fullInterest;
  }

  double get dueAmount {
    return amountGiven + compoundInterest - amountReceived;
  }

  bool get isOverdue {
    return DateTime.now().difference(date).inDays > duration;
  }

  int get daysRemaining {
    final daysPassed = DateTime.now().difference(date).inDays;
    return duration - daysPassed;
  }

  int get overdueDays {
    final daysPassed = DateTime.now().difference(date).inDays;
    return daysPassed > duration ? daysPassed - duration : 0;
  }

  double get totalDueAtDueDate {
    // This is the fixed amount due at the end of the agreed period
    final agreedPeriodInterest = (amountGiven * interestRate) / 100 * duration;
    return amountGiven + agreedPeriodInterest;
  }

  double get overdueInterest {
    if (!isOverdue) return 0.0;

    final overdueDays = this.overdueDays;
    final overdueInterestPerDay = (totalDueAtDueDate * interestRate) / 100;
    return overdueInterestPerDay * overdueDays;
  }

  // Additional getters for comprehensive display
  int get daysPassed {
    return DateTime.now().difference(date).inDays;
  }

  double get agreedPeriodInterest {
    return (amountGiven * interestRate) / 100 * duration;
  }

  double get currentInterest {
    return compoundInterest;
  }

  DateTime get dueDate {
    return date.add(Duration(days: duration));
  }

  bool get isFullyPaid {
    return dueAmount <= 0;
  }

  double get remainingPrincipal {
    return amountGiven - amountReceived;
  }

  // New getter for immediate total due (principal + full interest)
  double get immediateTotalDue {
    return amountGiven + agreedPeriodInterest;
  }
}
