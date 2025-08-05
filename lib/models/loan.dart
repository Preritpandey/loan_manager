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

  // Calculate effective days for interest calculation (for current status)
  int get effectiveDaysForInterest {
    final daysPassed = this.daysPassed;

    // Rule 1: Minimum one-month interest (30 days) for loans up to 30 days
    if (duration <= 30) {
      // For short loans, charge minimum 30 days or actual days if longer
      return daysPassed <= 30 ? 30 : daysPassed;
    }

    // Rule 2: For loans longer than 30 days, use full duration if not yet matured,
    // or actual days passed if overdue
    if (daysPassed <= duration) {
      // Loan not yet matured - use actual days passed (for current calculation)
      return daysPassed;
    } else {
      // Loan is overdue - use actual days passed
      return daysPassed;
    }
  }

  // Calculate effective days for the agreed loan period (for total due calculation)
  int get agreedPeriodDays {
    // Rule 1: Minimum one-month interest (30 days) for loans up to 30 days
    if (duration <= 30) {
      return 30; // Always minimum 30 days for short loans
    }

    // Rule 2: For loans longer than 30 days, use the full agreed duration
    return duration;
  }

  // Convert annual interest rate to daily rate
  double get dailyInterestRate {
    return interestRate / 365;
  }

  // Calculate interest (uses agreed period for total due calculations)
  double get calculatedInterest {
    // For most calculations, we want the agreed period interest
    return agreedPeriodInterest;
  }

  // Calculate current interest based on actual time passed (for current status display)
  double get currentCalculatedInterest {
    double currentBalance = amountGiven;
    double totalInterest = 0.0;
    int lastCalculationDay = 0;
    final effectiveDays = effectiveDaysForInterest;

    // Sort partial repayments by date
    final sortedRepayments = List<PartialRepayment>.from(partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));

    // If no partial repayments, calculate simple interest for current period
    if (sortedRepayments.isEmpty) {
      return (amountGiven * dailyInterestRate * effectiveDays) / 100;
    }

    // Calculate interest for each period between repayments
    for (final repayment in sortedRepayments) {
      final daysSinceLastCalculation =
          repayment.daysSinceLoan - lastCalculationDay;
      if (daysSinceLastCalculation > 0) {
        totalInterest +=
            (currentBalance * dailyInterestRate * daysSinceLastCalculation) / 100;
      }
      currentBalance -= repayment.amount;
      lastCalculationDay = repayment.daysSinceLoan;
    }

    // Calculate interest for the remaining period
    final remainingDays = effectiveDays - lastCalculationDay;
    if (remainingDays > 0) {
      totalInterest += (currentBalance * dailyInterestRate * remainingDays) / 100;
    }

    return totalInterest;
  }

  // Calculate interest for the full agreed period (for total due calculation) 
  double get agreedPeriodInterest {
    double currentBalance = amountGiven;
    double totalInterest = 0.0;
    int lastCalculationDay = 0;
    final effectiveDays = agreedPeriodDays;

    // Sort partial repayments by date
    final sortedRepayments = List<PartialRepayment>.from(partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));

    // If no partial repayments, calculate simple interest for agreed period
    if (sortedRepayments.isEmpty) {
      return (amountGiven * dailyInterestRate * effectiveDays) / 100;
    }

    // Calculate interest for each period between repayments (limited to agreed period)
    for (final repayment in sortedRepayments) {
      if (repayment.daysSinceLoan > effectiveDays) break; // Don't go beyond agreed period
      
      final daysSinceLastCalculation =
          repayment.daysSinceLoan - lastCalculationDay;
      if (daysSinceLastCalculation > 0) {
        totalInterest +=
            (currentBalance * dailyInterestRate * daysSinceLastCalculation) / 100;
      }
      currentBalance -= repayment.amount;
      lastCalculationDay = repayment.daysSinceLoan;
    }

    // Calculate interest for the remaining period (up to agreed period)
    final remainingDays = effectiveDays - lastCalculationDay;
    if (remainingDays > 0) {
      totalInterest += (currentBalance * dailyInterestRate * remainingDays) / 100;
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
      final overdueInterestPerDay = (totalDueAtDueDate * dailyInterestRate) / 100;
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
    // This is the amount due at the end of the agreed period with agreed period interest
    return amountGiven + agreedPeriodInterest;
  }

  double get overdueInterest {
    if (!isOverdue) return 0.0;

    final overdueDays = this.overdueDays;
    final overdueInterestPerDay = (totalDueAtDueDate * dailyInterestRate) / 100;
    return overdueInterestPerDay * overdueDays;
  }

  // Additional getters for comprehensive display
  int get daysPassed {
    return DateTime.now().difference(date).inDays;
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

  // New getter for immediate total due (principal + agreed period interest)
  double get immediateTotalDue {
    return amountGiven + agreedPeriodInterest;
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
    // Only save if the object is in a box (to avoid test errors)
    if (isInBox) {
      save();
    }
  }

  // Get current balance after all partial repayments
  double get currentBalance {
    return amountGiven -
        partialRepayments.fold(0.0, (sum, repayment) => sum + repayment.amount);
  }

  // Calculate interest for custom number of days
  double calculateCustomDaysInterest(int customDays) {
    return (amountGiven * dailyInterestRate * customDays) / 100;
  }

  // Calculate total amount for custom number of days
  double calculateCustomDaysTotal(int customDays) {
    return amountGiven + calculateCustomDaysInterest(customDays);
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
