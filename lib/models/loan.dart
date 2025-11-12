// models/loan.dart
import 'package:hive/hive.dart';
import 'package:list/utils/nepali_date_utils.dart';
part 'loan.g.dart';

@HiveType(typeId: 0)
class Loan extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(14)
  String loanId; // Unique identifier for each loan
  @HiveField(1)
  DateTime date;
  @HiveField(13)
  String? nepaliDateString; // Store Nepali date as string for backward compatibility
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
    this.nepaliDateString,
    String? loanId,
  }) : partialRepayments = partialRepayments ?? [],
       loanId = loanId ?? DateTime.now().millisecondsSinceEpoch.toString();

  // Factory constructor for creating loan with Nepali date
  factory Loan.withNepaliDate({
    required String name,
    required NepaliDate nepaliDate,
    required int duration,
    required double interestRate,
    required String type,
    required String jewelleryName,
    required String serialNumber,
    required String phone,
    required String address,
    required String description,
    required double amountGiven,
    double amountReceived = 0.0,
    List<PartialRepayment>? partialRepayments,
    String? loanId,
  }) {
    return Loan(
      name: name,
      date: nepaliDate.toGregorian(),
      duration: duration,
      interestRate: interestRate,
      type: type,
      jewelleryName: jewelleryName,
      serialNumber: serialNumber,
      phone: phone,
      address: address,
      description: description,
      amountGiven: amountGiven,
      amountReceived: amountReceived,
      partialRepayments: partialRepayments,
      nepaliDateString: nepaliDate.format(),
      loanId: loanId,
    );
  }

  // Accrued interest at an arbitrary date using ledger; optionally enforce min-30 rule
  double accruedInterestAt(DateTime asOf, {bool forSettlement = false}) {
    final s = _ledgerUpTo(asOf);
    double accrued = s['accrued'] ?? 0.0;
    final interestPaid = (s['interestPaid'] ?? 0.0) + (s['extraInterestPaid'] ?? 0.0);

    if (forSettlement) {
      final daysSinceStart = asOf.difference(date).inDays;
      if (daysSinceStart < 30) {
        final minInterest = (amountGiven * dailyInterestRate * 30) / 100;
        final shortfall = minInterest - (interestPaid + accrued);
        if (shortfall > 0) accrued += shortfall;
      }
    }
    return accrued;
  }

  // Remaining principal at an arbitrary date using ledger
  double remainingPrincipalAt(DateTime asOf) {
    final s = _ledgerUpTo(asOf);
    return s['principal'] ?? 0.0;
  }

  // Calculate effective days for interest calculation based on current date
  // Applies minimum 30 days only when evaluating settlement as of now.
  // For display purposes, this returns max(daysPassed, 30).
  int get effectiveDaysForInterest {
    final dp = daysPassed;
    return dp < 30 ? 30 : dp;
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
  // Using 365.25 to account for leap years and ensure consistent daily interest
  double get dailyInterestRate {
    return interestRate / 365.25;
  }

  // Calculate interest (uses agreed period for total due calculations)
  double get calculatedInterest {
    // For most calculations, we want the agreed period interest
    return agreedPeriodInterest;
  }

  // Internal: compute ledger up to a given date considering partial repayments.
  // Returns a map with keys: 'principal', 'accrued', 'interestPaid', 'extraInterestPaid'
  Map<String, double> _ledgerUpTo(DateTime asOf) {
    double principal = amountGiven;
    double accrued = 0.0;
    double interestPaid = 0.0; // interest actually paid (beyond principal)
    double extraInterestPaid =
        0.0; // interest paid that exceeds accrued (e.g., min 30-day enforcement)

    // Sort partial repayments by date
    final events = List<PartialRepayment>.from(partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime lastDate = date;

    for (final repayment in events.where((e) => !e.date.isAfter(asOf))) {
      // Accrue interest from lastDate to repayment date on current principal
      final days = repayment.date.difference(lastDate).inDays;
      if (days > 0 && principal > 0) {
        accrued += (principal * dailyInterestRate * days) / 100;
      }

      double payment = repayment.amount;

      if (payment < 0) {
        // Negative payment represents top-up (additional disbursement)
        // Increase principal by the absolute value. Do not change accrued/interestPaid.
        principal += (-payment);
        payment = 0.0;
      } else if (payment > 0) {
        // Principal-only marker: if daysSinceLoan == -2, skip paying accrued and reduce principal directly
        if (repayment.daysSinceLoan == -2) {
          final principalPortion = payment >= principal ? principal : payment;
          principal -= principalPortion;
          payment -= principalPortion;

          // Any leftover (shouldn't happen if clamped) is ignored for interest; treat as extra interest safeguard
          if (payment > 0) {
            extraInterestPaid += payment;
            payment = 0.0;
          }
        } else {
          // Apply payment to accrued interest first
          final interestPortion = payment <= accrued ? payment : accrued;
          accrued -= interestPortion;
          interestPaid += interestPortion;
          payment -= interestPortion;

          // Interest-only marker: if daysSinceLoan == -1, do NOT reduce principal.
          // Any remaining after paying accrued is treated as extra interest.
          if (payment > 0 && repayment.daysSinceLoan == -1) {
            extraInterestPaid += payment;
            payment = 0.0;
          } else {
            // Then apply remaining payment to principal
            if (payment > 0) {
              final principalPortion = payment >= principal ? principal : payment;
              principal -= principalPortion;
              payment -= principalPortion;
            }

            // If there's still leftover after clearing both, count it as extra interest paid
            if (payment > 0) {
              extraInterestPaid += payment;
              payment = 0.0;
            }
          }
        }
      }

      // Move lastDate to this repayment date
      lastDate = repayment.date;
    }

    // Accrue interest from last event to asOf on remaining principal
    final tailDays = asOf.difference(lastDate).inDays;
    if (tailDays > 0 && principal > 0) {
      accrued += (principal * dailyInterestRate * tailDays) / 100;
    }

    return {
      'principal': principal,
      'accrued': accrued,
      'interestPaid': interestPaid,
      'extraInterestPaid': extraInterestPaid,
    };
  }

  // Interest accrued up to now without enforcing the 30-day minimum settlement rule
  double get accruedInterestNowNoMin {
    final s = _ledgerUpTo(DateTime.now());
    return s['accrued'] ?? 0.0;
  }

  // Total interest paid so far (portion of repayments that went to interest)
  double get totalInterestPaidSoFar {
    final s = _ledgerUpTo(DateTime.now());
    return (s['interestPaid'] ?? 0.0) + (s['extraInterestPaid'] ?? 0.0);
  }

  // Calculate current interest based on actual time passed and partial repayments
  // with enforcement of minimum 30 days only when treated as settlement now.
  // For overdue loans, applies compound interest after the due date.
  double get currentCalculatedInterest {
    final asOf = DateTime.now();
    final totalDays = asOf.difference(date).inDays;
    
    // If no partial repayments/top-ups, apply capitalization-at-due-date rule
    if (partialRepayments.isEmpty) {
      final firstPhaseDays = totalDays <= duration ? totalDays : duration;
      final overdueDays = totalDays > duration ? (totalDays - duration) : 0;

      // Calculate daily interest rate from annual rate
      final dailyRate = interestRate / 365.25;
      
      // For non-overdue period (before due date)
      double firstPhaseInterest = 0.0;
      if (firstPhaseDays > 0) {
        // Calculate interest for the initial period up to due date
        firstPhaseInterest = (amountGiven * dailyRate * firstPhaseDays) / 100;
      }
      
      // If not overdue, return just the first phase interest (with minimum 30 days if applicable)
      if (overdueDays <= 0) {
        // Apply minimum 30 days interest if settling early
        if (firstPhaseDays < 30) {
          final minInterest = (amountGiven * dailyRate * 30) / 100;
          return minInterest > firstPhaseInterest ? minInterest : firstPhaseInterest;
        }
        return firstPhaseInterest;
      }
      
      // For overdue period (after due date) - Apply compounding
      // Calculate interest for the initial period (up to due date)
      final firstPhaseInterestToDue = (amountGiven * dailyRate * duration) / 100;
      
      // Calculate new principal at due date (original principal + interest up to due date)
      final principalAtDue = amountGiven + firstPhaseInterestToDue;
      
      // Calculate interest for the overdue period on the new principal
      final overdueInterest = (principalAtDue * dailyRate * overdueDays) / 100;
      
      // Return total interest (initial period + overdue period with compounding)
      return firstPhaseInterestToDue + overdueInterest;
    }

    // For loans with partial repayments, use the ledger
    final s = _ledgerUpTo(asOf);
    double accrued = s['accrued'] ?? 0.0;
    final interestPaid = (s['interestPaid'] ?? 0.0) + (s['extraInterestPaid'] ?? 0.0);
    
    // If the loan is overdue, we need to ensure the overdue interest is compounded
    if (isOverdue) {
      final dueDate = date.add(Duration(days: duration));
      final overdueDays = asOf.difference(dueDate).inDays;
      
      if (overdueDays > 0) {
        // Get the state of the loan at the due date
        final atDueDate = _ledgerUpTo(dueDate);
        final principalAtDue = atDueDate['principal'] ?? 0.0;
        final interestAtDue = atDueDate['accrued'] ?? 0.0;
        
        // Calculate the new principal (original principal + interest up to due date)
        final newPrincipal = principalAtDue + interestAtDue;
        
        // Calculate interest on the new principal for the overdue period
        final overdueInterest = (newPrincipal * dailyInterestRate * overdueDays) / 100;
        
        // Update the accrued interest to include the compounded overdue interest
        accrued = interestAtDue + overdueInterest + (s['accrued'] ?? 0.0);
      }
    }
    
    // Enforce minimum 30 days on early settlement check for non-overdue loans
    if (!isOverdue) {
      final daysSinceStart = asOf.difference(date).inDays;
      if (daysSinceStart < 30) {
        final minInterest = (amountGiven * dailyInterestRate * 30) / 100;
        final shortfall = minInterest - (interestPaid + accrued);
        if (shortfall > 0) accrued += shortfall;
      }
    }
    
    return accrued;
  }

  // Calculate interest generated over the full agreed period, respecting partial repayments
  // (sum of interest accrued regardless of whether it has been paid).
  double get agreedPeriodInterest {
    final endDate = date.add(Duration(days: agreedPeriodDays));
    final s = _ledgerUpTo(endDate);
    final accrued = s['accrued'] ?? 0.0;
    final interestPaid = (s['interestPaid'] ?? 0.0);
    return interestPaid + accrued;
  }

  double get acquiredInterest {
    // For compatibility, return current calculated interest (with min rule on settlement now)
    return currentCalculatedInterest;
  }

  // Current interest due as of now (principal + interest is total due),
  // enforcing minimum 30 days if within first 30 days and treated as settlement.
  double get compoundInterest {
    final asOf = DateTime.now();
    final s = _ledgerUpTo(asOf);
    double accrued = s['accrued'] ?? 0.0;
    final interestPaid =
        (s['interestPaid'] ?? 0.0) + (s['extraInterestPaid'] ?? 0.0);

    final daysSinceStart = asOf.difference(date).inDays;
    if (daysSinceStart < 30) {
      final minInterest = (amountGiven * dailyInterestRate * 30) / 100;
      final shortfall = minInterest - (interestPaid + accrued);
      if (shortfall > 0) accrued += shortfall;
    }
    return accrued;
  }

  // Outstanding balance now (principal + interest up to now)
  double get dueAmount {
    return outstandingDueAt(DateTime.now(), forSettlement: false);
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

  // Overdue interest is not applied beyond daily simple interest per the new rules.
  double get overdueInterest {
    return 0.0;
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
    // Remaining principal based on ledger (not naive amountGiven - amountReceived)
    final s = _ledgerUpTo(DateTime.now());
    return s['principal'] ?? 0.0;
  }

  // New getter for immediate total due (principal + agreed period interest)
  double get immediateTotalDue {
    return amountGiven + agreedPeriodInterest;
  }

  // Planned due based on agreed duration (principal + agreed period interest - received)
  double get plannedDue {
    return immediateTotalDue - amountReceived;
  }

  // Method to add partial repayment
  void addPartialRepayment(double amount, DateTime repaymentDate, {bool interestOnly = false, bool principalOnly = false}) {
    final computedDays = repaymentDate.difference(date).inDays;
    
    // For overall payments, we need to ensure the principal is fully paid off if the amount covers it
    if (!interestOnly && !principalOnly) {
      final s = _ledgerUpTo(repaymentDate);
      final currentPrincipal = s['principal'] ?? 0.0;
      final currentAccrued = s['accrued'] ?? 0.0;
      final totalOutstanding = currentPrincipal + currentAccrued;
      
      // If the payment covers the total outstanding, ensure principal is fully paid
      if (amount >= totalOutstanding) {
        // First, add a payment for the accrued interest
        if (currentAccrued > 0) {
          partialRepayments.add(
            PartialRepayment(
              amount: currentAccrued,
              date: repaymentDate,
              daysSinceLoan: -1, // Mark as interest payment
            ),
          );
        }
        
        // Then add a payment for the remaining principal
        if (currentPrincipal > 0) {
          partialRepayments.add(
            PartialRepayment(
              amount: currentPrincipal,
              date: repaymentDate,
              daysSinceLoan: -2, // Mark as principal payment
            ),
          );
        }
        
        amountReceived += amount;
        if (isInBox) save();
        return;
      }
    }
    
    // Default behavior for regular partial payments
    final daysSinceLoan = interestOnly
        ? -1
        : (principalOnly ? -2 : computedDays);
    
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

  // Method to add a top-up (additional disbursement) recorded as a negative ledger event
  void addTopUp(double amount, DateTime disbursementDate) {
    final daysSinceLoan = disbursementDate.difference(date).inDays;
    partialRepayments.add(
      PartialRepayment(
        amount: -amount, // negative to denote disbursement
        date: disbursementDate,
        daysSinceLoan: daysSinceLoan,
      ),
    );
    // Do NOT change amountReceived for top-ups
    if (isInBox) {
      save();
    }
  }

  // Get current balance (remaining principal) after all partial repayments using ledger
  double get currentBalance {
    final s = _ledgerUpTo(DateTime.now());
    return s['principal'] ?? 0.0;
  }

  // Calculate interest for custom number of days
  double calculateCustomDaysInterest(int customDays) {
    // Use outstanding principal as base to avoid charging interest on repaid amounts
    final principalBase = remainingPrincipal;
    return (principalBase * dailyInterestRate * customDays) / 100;
  }

  // Calculate total amount for custom number of days
  double calculateCustomDaysTotal(int customDays) {
    return remainingPrincipal + calculateCustomDaysInterest(customDays);
  }

  // Compute outstanding due at an arbitrary date.
  // If forSettlement is true and asOf is within 30 days, enforce minimum 30-day interest.
  double outstandingDueAt(DateTime asOf, {bool forSettlement = false}) {
    // Calculate total days including today
    final totalDays = asOf.difference(date).inDays + 1; // +1 to include both start and end days
    final isOverdue = totalDays > duration;
    
    // If no partial repayments/top-ups, apply capitalization-at-due-date rule
    if (partialRepayments.isEmpty) {
      final firstPhaseDays = totalDays <= duration ? totalDays : duration;
      final overdueDays = totalDays > duration ? (totalDays - duration) : 0;

      // For overdue loans, don't enforce the 30-day minimum interest rule
      final appliedFirstPhaseDays = (firstPhaseDays < 30 && forSettlement && !isOverdue) 
          ? 30 
          : firstPhaseDays;

      // Calculate first phase interest (up to due date or end of loan)
      final i1 = (amountGiven * dailyInterestRate * appliedFirstPhaseDays) / 100;
      
      if (!isOverdue) {
        return amountGiven + i1;
      }
      
      // For overdue loans, calculate with compound interest after due date
      final principalAtDue = amountGiven + (amountGiven * dailyInterestRate * duration) / 100;
      final i2 = (principalAtDue * dailyInterestRate * overdueDays) / 100;
      return amountGiven + i1 + i2;
    }
    
    // For loans with partial repayments, use the ledger
    final s = _ledgerUpTo(asOf);
    double principal = s['principal'] ?? 0.0;
    double accrued = s['accrued'] ?? 0.0;
    final interestPaid = (s['interestPaid'] ?? 0.0) + (s['extraInterestPaid'] ?? 0.0);

    // Only enforce 30-day minimum for non-overdue loans when forSettlement is true
    if (forSettlement && !isOverdue) {
      final daysSinceStart = asOf.difference(date).inDays + 1; // Include both start and end days
      if (daysSinceStart < 30) {
        final minInterest = (amountGiven * dailyInterestRate * 30) / 100;
        final shortfall = minInterest - (interestPaid + accrued);
        if (shortfall > 0) accrued += shortfall;
      }
    }

    return principal + accrued;
  }

  // Get last event date (loan start or last repayment)
  DateTime get lastEventDate {
    if (partialRepayments.isEmpty) return date;
    final events = List<PartialRepayment>.from(partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));
    return events.last.date;
  }

  // Get Nepali date
  NepaliDate get nepaliDate {
    if (nepaliDateString != null && nepaliDateString!.isNotEmpty) {
      final parsed = NepaliDate.parse(nepaliDateString!);
      if (parsed != null) return parsed;
    }
    // Fallback to conversion from Gregorian date
    return NepaliDate.fromGregorian(date);
  }

  // Set Nepali date
  void setNepaliDate(NepaliDate nepaliDate) {
    this.nepaliDateString = nepaliDate.format();
    this.date = nepaliDate.toGregorian();
    if (isInBox) {
      save();
    }
  }

  // Get formatted Nepali date string
  String get formattedNepaliDate {
    return nepaliDate.format();
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
