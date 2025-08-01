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
  @HiveField(12)
  List<PartialRepayment> partialRepayments;

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
    List<PartialRepayment>? partialRepayments,
  }) : partialRepayments = partialRepayments ?? [];

  // Calculate effective days for interest calculation
  int get effectiveDaysForInterest {
    final daysPassed = this.daysPassed;

    // Rule 1: Minimum one-month interest (30 days) for loans up to 30 days
    if (duration <= 30) {
      return daysPassed <= 30 ? 30 : daysPassed;
    }

    // Rule 2: For loans longer than 30 days, use actual days passed (up to duration)
    return daysPassed <= duration ? daysPassed : duration;
  }

  // Calculate interest based on remaining balance after partial repayments
  double get calculatedInterest {
    double currentBalance = amountGiven;
    double totalInterest = 0.0;
    int lastCalculationDay = 0;

    // Sort partial repayments by date
    final sortedRepayments = List<PartialRepayment>.from(partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate interest for each period between repayments
    for (final repayment in sortedRepayments) {
      final daysSinceLastCalculation =
          repayment.daysSinceLoan - lastCalculationDay;
      if (daysSinceLastCalculation > 0) {
        totalInterest +=
            (currentBalance * interestRate / 100) * daysSinceLastCalculation;
      }
      currentBalance -= repayment.amount;
      lastCalculationDay = repayment.daysSinceLoan;
    }

    // Calculate interest for the remaining period
    final remainingDays = effectiveDaysForInterest - lastCalculationDay;
    if (remainingDays > 0) {
      totalInterest += (currentBalance * interestRate / 100) * remainingDays;
    }

    return totalInterest;
  }

  double get acquiredInterest {
    // Use the new calculated interest method
    return calculatedInterest;
  }

  double get compoundInterest {
    // Base interest calculation
    double baseInterest = calculatedInterest;

    // If overdue, add additional interest on the total due amount
    if (isOverdue) {
      final totalDueAtDueDate = amountGiven + baseInterest;
      final overdueDays = this.overdueDays;
      final overdueInterestPerDay = (totalDueAtDueDate * interestRate) / 100;
      final overdueInterest = overdueInterestPerDay * overdueDays;
      return baseInterest + overdueInterest;
    }

    return baseInterest;
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
    // This is the amount due at the end of the agreed period with new interest calculation
    return amountGiven + calculatedInterest;
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
    return calculatedInterest;
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

  // New getter for immediate total due (principal + calculated interest)
  double get immediateTotalDue {
    return amountGiven + calculatedInterest;
  }

  // Method to add partial repayment
  void addPartialRepayment(double amount, DateTime repaymentDate) {
    final daysSinceLoan = repaymentDate.difference(date).inDays;
    partialRepayments.add(
      PartialRepayment(
        amount: amount,
        date: repaymentDate,
        daysSinceLoan: daysSinceLoan,
      ),
    );
    amountReceived += amount;
    save();
  }

  // Get current balance after all partial repayments
  double get currentBalance {
    return amountGiven -
        partialRepayments.fold(0.0, (sum, repayment) => sum + repayment.amount);
  }
}

// New class to track partial repayments
@HiveType(typeId: 1)
class PartialRepayment {
  @HiveField(0)
  double amount;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int daysSinceLoan;

  PartialRepayment({
    required this.amount,
    required this.date,
    required this.daysSinceLoan,
  });
}
