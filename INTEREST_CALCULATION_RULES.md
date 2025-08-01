# Interest Calculation Rules

This document explains the updated interest calculation rules implemented in the loan management system.

## Overview

The loan system now follows four main rules for calculating interest:

1. **Minimum One-Month Interest Rule**
2. **Daily Interest for More Than 1 Month**
3. **Early Repayment Adjustment**
4. **Partial Repayment Reduces Interest Calculation**

## Rule 1: Minimum One-Month Interest Rule

**If a user takes a loan for 20 days or less than 1 month, they will still have to pay interest for a full month (30 days).**

### Examples:

- **20-day loan**: Interest calculated for 30 days (minimum)
- **15-day loan**: Interest calculated for 30 days (minimum)
- **30-day loan**: Interest calculated for 30 days

### Implementation:

```dart
// For loans up to 30 days, minimum interest period is 30 days
if (duration <= 30) {
  return daysPassed <= 30 ? 30 : daysPassed;
}
```

## Rule 2: Daily Interest for More Than 1 Month

**If the loan duration is more than 30 days, calculate interest on a daily basis.**

### Examples:

- **32-day loan**: Interest calculated for exactly 32 days
- **60-day loan**: Interest calculated for exactly 60 days
- **200-day loan**: Interest calculated for exactly 200 days

### Implementation:

```dart
// For loans longer than 30 days, use actual days passed
return daysPassed <= duration ? daysPassed : duration;
```

## Rule 3: Early Repayment Adjustment

**If a user takes a loan for a long period but repays it early, calculate interest only for the actual number of days the loan was held.**

### Examples:

- **200-day loan repaid after 100 days**: Interest calculated for 100 days only
- **60-day loan repaid after 45 days**: Interest calculated for 45 days only

### Implementation:

The system automatically calculates interest based on the actual days passed, not the originally agreed duration.

## Rule 4: Partial Repayment Reduces Interest Calculation

**If the user repays a portion of the principal during the loan term, interest should be calculated only on the remaining balance after repayment.**

### Examples:

#### Scenario 1: Single Partial Repayment

- **Loan**: ₹100,000 for 100 days at 2% daily interest
- **Partial repayment**: ₹50,000 after 50 days
- **Interest calculation**:
  - First 50 days: ₹100,000 × 2% × 50 = ₹100,000
  - Remaining 50 days: ₹50,000 × 2% × 50 = ₹50,000
  - **Total interest**: ₹150,000

#### Scenario 2: Multiple Partial Repayments

- **Loan**: ₹100,000 for 90 days at 2% daily interest
- **Repayment 1**: ₹30,000 after 30 days
- **Repayment 2**: ₹20,000 after 60 days
- **Interest calculation**:
  - Days 1-30: ₹100,000 × 2% × 30 = ₹60,000
  - Days 31-60: ₹70,000 × 2% × 30 = ₹42,000
  - Days 61-90: ₹50,000 × 2% × 30 = ₹30,000
  - **Total interest**: ₹132,000

### Implementation:

```dart
double get calculatedInterest {
  double currentBalance = amountGiven;
  double totalInterest = 0.0;
  int lastCalculationDay = 0;

  // Sort partial repayments by date
  final sortedRepayments = List<PartialRepayment>.from(partialRepayments)
    ..sort((a, b) => a.date.compareTo(b.date));

  // Calculate interest for each period between repayments
  for (final repayment in sortedRepayments) {
    final daysSinceLastCalculation = repayment.daysSinceLoan - lastCalculationDay;
    if (daysSinceLastCalculation > 0) {
      totalInterest += (currentBalance * interestRate / 100) * daysSinceLastCalculation;
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
```

## Technical Implementation

### New Model Fields

The `Loan` model now includes:

```dart
@HiveField(12)
List<PartialRepayment> partialRepayments;
```

### PartialRepayment Class

```dart
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
```

### Key Methods

1. **`effectiveDaysForInterest`**: Determines the effective days for interest calculation based on rules 1 and 2
2. **`calculatedInterest`**: Calculates interest considering partial repayments (rule 4)
3. **`addPartialRepayment`**: Adds a partial repayment to the loan
4. **`currentBalance`**: Returns the current balance after all partial repayments

### UI Features

The loan detail page now includes:

1. **Partial Repayment Section**: Allows users to add partial repayments with dates
2. **Repayment History**: Shows all partial repayments made
3. **Current Balance Display**: Shows the remaining balance after partial repayments
4. **Updated Interest Display**: Shows interest calculated according to new rules

## Benefits

1. **Fair Interest Calculation**: Customers only pay interest on the actual amount and time period
2. **Flexible Repayment**: Supports partial repayments without penalty
3. **Transparent Calculations**: All calculations are clearly visible and understandable
4. **Minimum Revenue Protection**: Ensures minimum one-month interest for short-term loans

## Testing

The system includes comprehensive tests in `test/interest_calculation_test.dart` that verify:

1. Minimum one-month interest rule
2. Daily interest for longer periods
3. Early repayment adjustments
4. Partial repayment calculations
5. Multiple partial repayment scenarios

## Migration

Existing loans will automatically use the new calculation rules. The system is backward compatible and will recalculate interest based on the new rules when accessed.

## Usage Examples

### Adding a Partial Repayment

```dart
// In the loan detail page
_loanController.addPartialRepayment(
  loan.serialNumber,
  50000.0, // Amount
  DateTime.now(), // Date
);
```

### Getting Current Balance

```dart
double currentBalance = loan.currentBalance;
```

### Getting Calculated Interest

```dart
double interest = loan.calculatedInterest;
```
