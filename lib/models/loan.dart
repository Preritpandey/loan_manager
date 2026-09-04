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
  @HiveField(16)
  List<InterestRateChange> interestRateChanges;

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
    List<InterestRateChange>? interestRateChanges,
    this.nepaliDateString,
    String? loanId,
  }) : partialRepayments = partialRepayments ?? [],
       interestRateChanges = interestRateChanges ?? [],
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
    List<InterestRateChange>? interestRateChanges,
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
      interestRateChanges: interestRateChanges,
      nepaliDateString: nepaliDate.format(),
      loanId: loanId,
    );
  }

  // Accrued interest at an arbitrary date using ledger; optionally enforce min-30 rule
  double accruedInterestAt(DateTime asOf, {bool forSettlement = false}) {
    final s = _ledgerUpTo(asOf);
    double accrued = s['accrued'] ?? 0.0;
    final interestPaid =
        (s['interestPaid'] ?? 0.0) + (s['extraInterestPaid'] ?? 0.0);

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

  double _interestForDays(double principal, int days, {double? rate}) {
    if (days <= 0 || principal <= 0) return 0.0;
    final appliedRate = rate ?? interestRate;

    // A completed 365-day loan year earns the configured annual rate exactly.
    // Shorter spans still use the app's existing daily-rate calculation.
    if (days == 365) {
      return principal * appliedRate / 100;
    }

    return (principal * (appliedRate / 365.25) * days) / 100;
  }

  List<InterestRateChange> get sortedInterestRateChanges {
    return interestRateChanges
        .map((change) {
          final effectiveDate = _effectiveDateForRateChange(
            change.effectiveDate,
          );
          if (effectiveDate == change.effectiveDate) return change;

          return InterestRateChange(
            previousRate: change.previousRate,
            newRate: change.newRate,
            effectiveDate: effectiveDate,
            createdAt: change.createdAt,
            previousCalculatedDue: change.previousCalculatedDue,
            recalculatedDue: change.recalculatedDue,
            adjustmentAmount: change.adjustmentAmount,
          );
        })
        .toList()
      ..sort((a, b) => a.effectiveDate.compareTo(b.effectiveDate));
  }

  double get originalInterestRate {
    final changes = sortedInterestRateChanges;
    if (changes.isEmpty) return interestRate;
    return changes.first.previousRate;
  }

  double interestRateAt(DateTime at) {
    var rate = originalInterestRate;
    for (final change in sortedInterestRateChanges) {
      if (change.effectiveDate.isAfter(at)) break;
      rate = change.newRate;
    }
    return rate;
  }

  double _interestForDateRange(double principal, DateTime start, DateTime end) {
    if (!end.isAfter(start) || principal <= 0) return 0.0;

    var cursor = start;
    var interest = 0.0;
    final changes = sortedInterestRateChanges
        .where((change) => change.effectiveDate.isAfter(start))
        .where((change) => change.effectiveDate.isBefore(end))
        .toList();

    for (final change in changes) {
      final days = change.effectiveDate.difference(cursor).inDays;
      interest += _interestForDays(
        principal,
        days,
        rate: interestRateAt(cursor),
      );
      cursor = change.effectiveDate;
    }

    final tailDays = end.difference(cursor).inDays;
    interest += _interestForDays(
      principal,
      tailDays,
      rate: interestRateAt(cursor),
    );
    return interest;
  }

  DateTime _effectiveDateForRateChange(DateTime requestedDate) {
    final asOf = requestedDate.isBefore(date) ? date : requestedDate;
    final affectedStart = _firstUnsettledInterestPeriodStart(asOf);
    if (affectedStart == null) return asOf;
    return affectedStart.isBefore(date) ? date : affectedStart;
  }

  DateTime? _firstUnsettledInterestPeriodStart(DateTime asOf) {
    final end = asOf.add(const Duration(days: 1));
    final periodDays = duration > 0 ? duration : 365;
    final events = partialRepayments
        .where((event) => !event.date.isAfter(asOf))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final periodStarts = <DateTime>[];
    final interestBalances = <double>[];
    var principal = amountGiven;
    var accruedInterest = 0.0;
    var currentPeriodStart = date;
    var cursor = date;
    var nextBoundary = date.add(Duration(days: periodDays));
    var eventIndex = 0;

    DateTime normalizeEventDate(DateTime eventDate) {
      if (eventDate.isBefore(date)) return date;
      if (eventDate.isAfter(end)) return end;
      return eventDate;
    }

    void payOldestInterest(double payment) {
      var remaining = payment;
      final accruedPayment = remaining > accruedInterest
          ? accruedInterest
          : remaining;
      accruedInterest -= accruedPayment;
      remaining -= accruedPayment;

      for (var i = 0; i < interestBalances.length && remaining > 0; i++) {
        final paid = remaining > interestBalances[i]
            ? interestBalances[i]
            : remaining;
        interestBalances[i] -= paid;
        remaining -= paid;
      }

      if (remaining > 0) {
        final principalPayment = remaining > principal ? principal : remaining;
        principal -= principalPayment;
      }
    }

    void applyPayment(PartialRepayment event) {
      var payment = event.amount;
      if (payment < 0) {
        principal += -payment;
        return;
      }

      if (event.daysSinceLoan == -2) {
        final principalPayment = payment > principal ? principal : payment;
        principal -= principalPayment;
        return;
      }

      payOldestInterest(payment);
    }

    while (cursor.isBefore(end)) {
      final hasEvent = eventIndex < events.length;
      final eventDate = hasEvent
          ? normalizeEventDate(events[eventIndex].date)
          : null;

      var nextCut = end;
      if (nextBoundary.isBefore(nextCut)) {
        nextCut = nextBoundary;
      }
      if (eventDate != null &&
          (eventDate.isBefore(nextCut) || eventDate.isAtSameMomentAs(nextCut))) {
        nextCut = eventDate;
      }

      if (nextCut.isAfter(cursor)) {
        final capitalizedInterest = interestBalances.fold<double>(
          0.0,
          (sum, balance) => sum + balance,
        );
        accruedInterest += _interestForDays(
          principal + capitalizedInterest,
          nextCut.difference(cursor).inDays,
        );
        cursor = nextCut;
      }

      while (eventIndex < events.length &&
          normalizeEventDate(events[eventIndex].date).isAtSameMomentAs(cursor)) {
        applyPayment(events[eventIndex]);
        eventIndex += 1;
      }

      if (cursor.isAtSameMomentAs(nextBoundary) ||
          cursor.isAfter(nextBoundary)) {
        periodStarts.add(currentPeriodStart);
        interestBalances.add(accruedInterest);
        accruedInterest = 0.0;
        currentPeriodStart = nextBoundary;
        nextBoundary = nextBoundary.add(const Duration(days: 365));
      }
    }

    const epsilon = 0.005;
    for (var i = 0; i < interestBalances.length; i++) {
      if (interestBalances[i] > epsilon) return periodStarts[i];
    }
    if (accruedInterest > epsilon) return currentPeriodStart;
    return null;
  }

  int _interestPeriodNumberFor(DateTime periodStart) {
    final firstBoundary = date.add(Duration(days: duration > 0 ? duration : 365));
    if (periodStart.isBefore(firstBoundary)) return 1;
    final daysAfterFirstPeriod = periodStart.difference(firstBoundary).inDays;
    return 2 + (daysAfterFirstPeriod ~/ 365);
  }

  int _elapsedInterestPeriodNumberAt(DateTime asOf) {
    final end = asOf.add(const Duration(days: 1));
    final firstBoundary = date.add(Duration(days: duration > 0 ? duration : 365));
    if (!end.isAfter(firstBoundary)) return 1;
    final daysAfterFirstPeriod = end.difference(firstBoundary).inDays;
    return 1 + ((daysAfterFirstPeriod + 364) ~/ 365);
  }

  String rateChangeAffectedPeriodsLabel(
    InterestRateChange change, {
    DateTime? asOf,
  }) {
    final startPeriod = _interestPeriodNumberFor(change.effectiveDate);
    final endPeriod = _elapsedInterestPeriodNumberAt(asOf ?? DateTime.now());
    final normalizedEnd = endPeriod < startPeriod ? startPeriod : endPeriod;
    return startPeriod == normalizedEnd
        ? 'Year $startPeriod'
        : 'Year $startPeriod - Year $normalizedEnd';
  }

  _DueSimulation _simulateDueAt(DateTime asOf, {bool forSettlement = false}) {
    final end = asOf.add(const Duration(days: 1));
    final periodDays = duration > 0 ? duration : 365;
    final events = partialRepayments
        .where((event) => !event.date.isAfter(asOf))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    var principal = amountGiven;
    var capitalizedInterest = 0.0;
    var accruedInterest = 0.0;
    var paidInterest = 0.0;
    var cursor = date;
    var nextBoundary = date.add(Duration(days: periodDays));
    var eventIndex = 0;

    DateTime normalizeEventDate(DateTime eventDate) {
      if (eventDate.isBefore(date)) return date;
      if (eventDate.isAfter(end)) return end;
      return eventDate;
    }

    void applyPayment(PartialRepayment event) {
      var payment = event.amount;
      if (payment < 0) {
        principal += -payment;
        return;
      }

      if (event.daysSinceLoan == -2) {
        final principalPayment = payment > principal ? principal : payment;
        principal -= principalPayment;
        return;
      }

      final accruedPayment = payment > accruedInterest
          ? accruedInterest
          : payment;
      accruedInterest -= accruedPayment;
      paidInterest += accruedPayment;
      payment -= accruedPayment;

      final capitalizedPayment = payment > capitalizedInterest
          ? capitalizedInterest
          : payment;
      capitalizedInterest -= capitalizedPayment;
      paidInterest += capitalizedPayment;
      payment -= capitalizedPayment;

      if (event.daysSinceLoan != -1 && payment > 0) {
        final principalPayment = payment > principal ? principal : payment;
        principal -= principalPayment;
      } else if (payment > 0) {
        paidInterest += payment;
      }
    }

    while (cursor.isBefore(end)) {
      final hasEvent = eventIndex < events.length;
      final eventDate = hasEvent
          ? normalizeEventDate(events[eventIndex].date)
          : null;

      var nextCut = end;
      if (nextBoundary.isBefore(nextCut)) {
        nextCut = nextBoundary;
      }
      if (eventDate != null &&
          (eventDate.isBefore(nextCut) || eventDate.isAtSameMomentAs(nextCut))) {
        nextCut = eventDate;
      }

      if (nextCut.isAfter(cursor)) {
        final base = principal + capitalizedInterest;
        accruedInterest += _interestForDateRange(base, cursor, nextCut);
        cursor = nextCut;
      }

      while (eventIndex < events.length &&
          normalizeEventDate(events[eventIndex].date).isAtSameMomentAs(cursor)) {
        applyPayment(events[eventIndex]);
        eventIndex += 1;
      }

      if (cursor.isAtSameMomentAs(nextBoundary) ||
          cursor.isAfter(nextBoundary)) {
        capitalizedInterest += accruedInterest;
        accruedInterest = 0.0;
        nextBoundary = nextBoundary.add(const Duration(days: 365));
      }
    }

    if (forSettlement) {
      final daysSinceStart = asOf.difference(date).inDays + 1;
      final isOverdueAtDate = daysSinceStart > duration;
      if (!isOverdueAtDate && daysSinceStart < 30) {
        final minInterest = (amountGiven * dailyInterestRate * 30) / 100;
        final interestAccounted =
            paidInterest + capitalizedInterest + accruedInterest;
        final shortfall = minInterest - interestAccounted;
        if (shortfall > 0) accruedInterest += shortfall;
      }
    }

    return _DueSimulation(
      principal: principal,
      capitalizedInterest: capitalizedInterest,
      accruedInterest: accruedInterest,
    );
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
        accrued += interestRateChanges.isEmpty
            ? (principal * dailyInterestRate * days) / 100
            : _interestForDateRange(principal, lastDate, repayment.date);
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
              final principalPortion = payment >= principal
                  ? principal
                  : payment;
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
      accrued += interestRateChanges.isEmpty
          ? (principal * dailyInterestRate * tailDays) / 100
          : _interestForDateRange(principal, lastDate, asOf);
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
    return (outstandingDueAt(asOf, forSettlement: true) -
            remainingPrincipalAt(asOf))
        .clamp(0.0, double.infinity);
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
    return (outstandingDueAt(asOf, forSettlement: true) -
            remainingPrincipalAt(asOf))
        .clamp(0.0, double.infinity);
  }

  // Outstanding balance now (principal + interest up to now)
  double get dueAmount {
    return outstandingDueAt(DateTime.now(), forSettlement: false);
  }

  bool get isOverdue {
    // If the loan is fully paid, it can't be overdue
    if (isFullyPaid) return false;

    // Check if current date is past the due date
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

  // Overdue interest is included through outstandingDueAt's period simulation.
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
  void addPartialRepayment(
    double amount,
    DateTime repaymentDate, {
    bool interestOnly = false,
    bool principalOnly = false,
  }) {
    final computedDays = repaymentDate.difference(date).inDays;

    // Get current state before making any changes
    final currentState = _ledgerUpTo(repaymentDate);
    final currentPrincipal = currentState['principal'] ?? 0.0;
    final currentAccrued = currentState['accrued'] ?? 0.0;
    final totalOutstanding = currentPrincipal + currentAccrued;

    // For overall payments, handle the full payment logic
    if (!interestOnly && !principalOnly) {
      // If the payment covers the total outstanding, ensure principal is fully paid
      if (amount >= totalOutstanding) {
        // Check if loan was overdue before processing payment
        final wasOverdue = repaymentDate.difference(date).inDays > duration;

        // First, add a payment for the accrued interest if any
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

        // If loan was overdue and payment covers total interest or total due, clear overdue status
        if (wasOverdue && amount >= (currentAccrued + currentPrincipal)) {
          extendDurationToClearOverdue(repaymentDate);
        }

        if (isInBox) save();
        return;
      } else {
        // For partial overall payments, handle it as a regular payment
        // that should be applied to both interest and principal
        var remainingAmount = amount;

        // Pay off any accrued interest first
        if (currentAccrued > 0 && remainingAmount > 0) {
          final interestPayment = remainingAmount <= currentAccrued
              ? remainingAmount
              : currentAccrued;

          partialRepayments.add(
            PartialRepayment(
              amount: interestPayment,
              date: repaymentDate,
              daysSinceLoan: -1, // Mark as interest payment
            ),
          );
          remainingAmount -= interestPayment;
        }

        // Apply remaining to principal
        if (remainingAmount > 0 && currentPrincipal > 0) {
          final principalPayment = remainingAmount <= currentPrincipal
              ? remainingAmount
              : currentPrincipal;

          partialRepayments.add(
            PartialRepayment(
              amount: principalPayment,
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

    // Check if loan was overdue before processing payment
    final wasOverdue = repaymentDate.difference(date).inDays > duration;

    // Calculate total interest and total due BEFORE adding payment (since ledger will change after)
    final totalDue = outstandingDueAt(repaymentDate, forSettlement: false);
    final remainingPrincipal = remainingPrincipalAt(repaymentDate);
    final totalInterest = totalDue - remainingPrincipal;

    partialRepayments.add(
      PartialRepayment(
        amount: amount,
        date: repaymentDate,
        daysSinceLoan: daysSinceLoan,
      ),
    );
    amountReceived += amount;

    // Check if payment clears overdue status
    // If loan was overdue and payment >= total interest OR payment >= total due, extend duration
    if (wasOverdue && (amount >= totalInterest || amount >= totalDue)) {
      extendDurationToClearOverdue(repaymentDate);
    }

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

  InterestRateChangePreview previewInterestRateChange(
    double newRate,
    DateTime effectiveDate,
  ) {
    final asOf = effectiveDate.isBefore(date) ? date : effectiveDate;
    final appliedEffectiveDate = _effectiveDateForRateChange(effectiveDate);
    final beforeDue = outstandingDueAt(asOf, forSettlement: false);
    final previousRate = interestRateAt(appliedEffectiveDate);
    final existingRate = interestRate;

    final previewChange = InterestRateChange(
      previousRate: previousRate,
      newRate: newRate,
      effectiveDate: appliedEffectiveDate,
      createdAt: DateTime.now(),
      previousCalculatedDue: beforeDue,
      recalculatedDue: beforeDue,
      adjustmentAmount: 0.0,
    );

    interestRate = newRate;
    interestRateChanges.add(previewChange);
    final afterDue = outstandingDueAt(asOf, forSettlement: false);
    interestRateChanges.remove(previewChange);
    interestRate = existingRate;

    return InterestRateChangePreview(
      previousRate: previousRate,
      newRate: newRate,
      effectiveDate: appliedEffectiveDate,
      affectedPeriodsLabel: rateChangeAffectedPeriodsLabel(
        previewChange,
        asOf: asOf,
      ),
      previousCalculatedDue: beforeDue,
      recalculatedDue: afterDue,
      adjustmentAmount: afterDue - beforeDue,
    );
  }

  InterestRateChange changeInterestRate(double newRate, DateTime effectiveDate) {
    final preview = previewInterestRateChange(newRate, effectiveDate);
    final change = InterestRateChange(
      previousRate: preview.previousRate,
      newRate: preview.newRate,
      effectiveDate: preview.effectiveDate,
      createdAt: DateTime.now(),
      previousCalculatedDue: preview.previousCalculatedDue,
      recalculatedDue: preview.recalculatedDue,
      adjustmentAmount: preview.adjustmentAmount,
    );

    interestRate = newRate;
    interestRateChanges.add(change);
    interestRateChanges.sort(
      (a, b) => a.effectiveDate.compareTo(b.effectiveDate),
    );
    if (isInBox) save();
    return change;
  }

  InterestRateChange rateChangeDisplaySummary(InterestRateChange change) {
    final asOf = DateTime.now();
    final allChanges = List<InterestRateChange>.from(interestRateChanges);
    final orderedChanges = List<InterestRateChange>.from(allChanges)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final changeIndex = orderedChanges.indexOf(change);
    if (changeIndex == -1) return change;

    final effectiveDate = change.effectiveDate;
    final normalizedChange = InterestRateChange(
      previousRate: change.previousRate,
      newRate: change.newRate,
      effectiveDate: effectiveDate,
      createdAt: change.createdAt,
      previousCalculatedDue: change.previousCalculatedDue,
      recalculatedDue: change.recalculatedDue,
      adjustmentAmount: change.adjustmentAmount,
    );
    final previousChanges = orderedChanges.take(changeIndex).toList();
    final appliedChanges = [
      ...previousChanges,
      normalizedChange,
    ];
    final existingRate = interestRate;

    double calculateWith(List<InterestRateChange> changes, double fallbackRate) {
      interestRate = fallbackRate;
      interestRateChanges
        ..clear()
        ..addAll(changes);
      return outstandingDueAt(asOf, forSettlement: false);
    }

    try {
      final previousFallbackRate = previousChanges.isEmpty
          ? change.previousRate
          : previousChanges.last.newRate;
      final previousDue = calculateWith(
        previousChanges,
        previousFallbackRate,
      );
      final recalculatedDue = calculateWith(appliedChanges, change.newRate);

      return InterestRateChange(
        previousRate: change.previousRate,
        newRate: change.newRate,
        effectiveDate: effectiveDate,
        createdAt: change.createdAt,
        previousCalculatedDue: previousDue,
        recalculatedDue: recalculatedDue,
        adjustmentAmount: recalculatedDue - previousDue,
      );
    } finally {
      interestRate = existingRate;
      interestRateChanges
        ..clear()
        ..addAll(allChanges);
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
    final simulation = _simulateDueAt(asOf, forSettlement: forSettlement);
    return simulation.total.clamp(0.0, double.infinity);
  }

  // Get last event date (loan start or last repayment)
  DateTime get lastEventDate {
    if (partialRepayments.isEmpty) return date;
    final events = List<PartialRepayment>.from(partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));
    return events.last.date;
  }

  // Calculate total interest amount (including overdue interest) at a given date
  double getTotalInterestAt(DateTime asOf) {
    final outstanding = outstandingDueAt(asOf, forSettlement: false);
    final principal = remainingPrincipalAt(asOf);
    return outstanding - principal;
  }

  // Extend loan duration to clear overdue status
  // This extends the duration by one year from the payment date to prevent immediate re-overdue
  void extendDurationToClearOverdue(DateTime asOf) {
    final daysPassed = asOf.difference(date).inDays;
    if (daysPassed > duration) {
      // Extend duration by one year from the payment date to clear overdue status
      final oneYearFromNow = asOf.add(Duration(days: 365));
      final newDuration = oneYearFromNow.difference(date).inDays;
      duration = newDuration;
      if (isInBox) save();
    }
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

@HiveType(typeId: 5)
class InterestRateChange {
  @HiveField(0)
  double previousRate;

  @HiveField(1)
  double newRate;

  @HiveField(2)
  DateTime effectiveDate;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  double previousCalculatedDue;

  @HiveField(5)
  double recalculatedDue;

  @HiveField(6)
  double adjustmentAmount;

  InterestRateChange({
    required this.previousRate,
    required this.newRate,
    required this.effectiveDate,
    required this.createdAt,
    required this.previousCalculatedDue,
    required this.recalculatedDue,
    required this.adjustmentAmount,
  });

  bool get isIncrease => newRate > previousRate;
  bool get isDecrease => newRate < previousRate;
}

class InterestRateChangePreview {
  final double previousRate;
  final double newRate;
  final DateTime effectiveDate;
  final String affectedPeriodsLabel;
  final double previousCalculatedDue;
  final double recalculatedDue;
  final double adjustmentAmount;

  InterestRateChangePreview({
    required this.previousRate,
    required this.newRate,
    required this.effectiveDate,
    required this.affectedPeriodsLabel,
    required this.previousCalculatedDue,
    required this.recalculatedDue,
    required this.adjustmentAmount,
  });

  bool get isIncrease => newRate > previousRate;
  bool get isDecrease => newRate < previousRate;
}

class _DueSimulation {
  final double principal;
  final double capitalizedInterest;
  final double accruedInterest;

  const _DueSimulation({
    required this.principal,
    required this.capitalizedInterest,
    required this.accruedInterest,
  });

  double get total => principal + capitalizedInterest + accruedInterest;
}
