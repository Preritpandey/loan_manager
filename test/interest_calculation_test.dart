import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';

void main() {
  group('Interest Calculation Tests', () {
    test('Annual interest rate calculation example', () {
      // Example with annual interest rates:
      // Loan 1: ₹10,000 at 20% annual for 150 days 
      // Daily rate = 20% / 365 = 0.0548%
      // Interest = (10,000 × 0.0548% × 150) / 100 = ₹821.92
      // Total = ₹10,821.92

      final loan1 = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 150,
        interestRate: 20.0, // 20% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain 1',
        serialNumber: 'TEST001',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      final loan2 = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 100,
        interestRate: 25.0, // 25% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain 2',
        serialNumber: 'TEST002',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 20000.0,
      );

      final loan3 = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 180,
        interestRate: 30.0, // 30% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain 3',
        serialNumber: 'TEST003',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 15000.0,
      );

      // Test individual calculations with annual-to-daily conversion
      // Loan 1: (10,000 × 20/365 × 150) / 100 = 821.92
      expect(loan1.calculatedInterest, closeTo(821.92, 0.01));
      expect(loan1.immediateTotalDue, closeTo(10821.92, 0.01));

      // Loan 2: (20,000 × 25/365 × 100) / 100 = 1369.86
      expect(loan2.calculatedInterest, closeTo(1369.86, 0.01));
      expect(loan2.immediateTotalDue, closeTo(21369.86, 0.01));

      // Loan 3: (15,000 × 30/365 × 180) / 100 = 2219.18
      expect(loan3.calculatedInterest, closeTo(2219.18, 0.01));
      expect(loan3.immediateTotalDue, closeTo(17219.18, 0.01));

      // Test that daily rate conversion is working
      expect(loan1.dailyInterestRate, closeTo(20.0/365, 0.0001));
      expect(loan2.dailyInterestRate, closeTo(25.0/365, 0.0001));
      expect(loan3.dailyInterestRate, closeTo(30.0/365, 0.0001));
    });

    test('Annual interest rate conversion to daily rate', () {
      // Test case 1: 20% annual rate should convert to daily rate
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 30,
        interestRate: 20.0, // 20% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST001',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // Daily rate should be 20% / 365 = 0.05479%
      expect(loan.dailyInterestRate, closeTo(20.0/365, 0.0001));

      // Interest calculation: (10,000 × (20/365) × 30) / 100 = 164.38
      final expectedInterest = (10000.0 * (20.0/365) * 30) / 100;
      expect(loan.calculatedInterest, closeTo(expectedInterest, 0.01));
    });

    test('User example: 20% annual rate for 150 days', () {
      // Test the user's example: 20% annual rate, 150 days
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 150,
        interestRate: 20.0, // 20% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST002',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // dailyRate = 20% / 365 = 0.05479%
      // totalInterest = (10,000 × 0.05479% × 150) / 100 = 821.92
      // totalAmount = 10,000 + 821.92 = 10,821.92
      final expectedDailyRate = 20.0 / 365;
      final expectedInterest = (10000.0 * expectedDailyRate * 150) / 100;
      final expectedTotal = 10000.0 + expectedInterest;

      expect(loan.dailyInterestRate, closeTo(expectedDailyRate, 0.0001));
      expect(loan.calculatedInterest, closeTo(expectedInterest, 0.01));
      expect(loan.immediateTotalDue, closeTo(expectedTotal, 0.01));
    });

    test('Different annual rates calculation', () {
      // Test different annual interest rates
      final loan15Percent = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365, // Full year
        interestRate: 15.0, // 15% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST003',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // For a full year at 15% annual, interest should be approximately 15% of principal
      // (10,000 × 15/365 × 365) / 100 = 1500
      final expectedInterest = (10000.0 * 15.0 * 365) / (365 * 100);
      expect(loan15Percent.calculatedInterest, closeTo(expectedInterest, 0.01));
      expect(loan15Percent.calculatedInterest, closeTo(1500.0, 0.01));
    });

    test('Overdue yearly interest compounds on previous due amount', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_OVERDUE_YEARLY',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      DateTime asOfCompletedYears(int years) {
        return loan.date.add(Duration(days: (365 * years) - 1));
      }

      expect(
        loan.outstandingDueAt(asOfCompletedYears(2), forSettlement: false),
        closeTo(169000.0, 0.01),
      );
      expect(
        loan.outstandingDueAt(asOfCompletedYears(3), forSettlement: false),
        closeTo(219700.0, 0.01),
      );
      expect(
        loan.outstandingDueAt(asOfCompletedYears(4), forSettlement: false),
        closeTo(285610.0, 0.01),
      );
    });

    test('No rate change keeps overdue compounding unchanged', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_NO_RATE_CHANGE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final asOf = loan.date.add(const Duration(days: (365 * 3) - 1));
      expect(
        loan.outstandingDueAt(asOf, forSettlement: false),
        closeTo(219700.0, 0.01),
      );
    });

    test('Interest-only collection resets paid year carry-forward base', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_INTEREST_ONLY_COMPOUND_BASE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.addPartialRepayment(
        30000.0,
        loan.date.add(const Duration(days: 365)),
        interestOnly: true,
      );

      final asOf = loan.date.add(const Duration(days: (365 * 3) - 1));
      expect(
        loan.outstandingDueAt(asOf, forSettlement: false),
        closeTo(169000.0, 0.01),
      );
      expect(loan.remainingPrincipalAt(asOf), closeTo(100000.0, 0.01));
      expect(loan.getTotalInterestAt(asOf), closeTo(69000.0, 0.01));
    });

    test('Multiple paid years reset carry-forward for each settled year', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_MULTIPLE_PAID_YEARS',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.addPartialRepayment(
        30000.0,
        loan.date.add(const Duration(days: 365)),
        interestOnly: true,
      );
      loan.addPartialRepayment(
        30000.0,
        loan.date.add(const Duration(days: 730)),
        interestOnly: true,
      );

      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 3) - 1)),
          forSettlement: false,
        ),
        closeTo(130000.0, 0.01),
      );
      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 4) - 1)),
          forSettlement: false,
        ),
        closeTo(169000.0, 0.01),
      );
    });

    test('Rate decrease recalculates unpaid overdue years sequentially', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.changeInterestRate(25.0, loan.date.add(const Duration(days: 365)));

      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 3) - 1)),
          forSettlement: false,
        ),
        closeTo(203125.0, 0.01),
      );
      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 4) - 1)),
          forSettlement: false,
        ),
        closeTo(253906.25, 0.01),
      );
    });

    test('Rate decrease preserves already-paid interest collection', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE_PAID_INTEREST',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.addPartialRepayment(
        30000.0,
        loan.date.add(const Duration(days: 365)),
        interestOnly: true,
      );
      loan.changeInterestRate(25.0, loan.date.add(const Duration(days: 365)));

      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 3) - 1)),
          forSettlement: false,
        ),
        closeTo(156250.0, 0.01),
      );
    });

    test('Rate decrease from year 3 reprices remaining unpaid periods', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE_LATE_EDIT',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final paidThroughDate = loan.date.add(const Duration(days: 365));
      final yearTwoStart = loan.date.add(const Duration(days: 365));
      final yearThreeStart = loan.date.add(const Duration(days: 730));
      final threeYearDate = loan.date.add(const Duration(days: (365 * 3) - 1));

      loan.addPartialRepayment(30000.0, paidThroughDate, interestOnly: true);
      final change = loan.changeInterestRate(25.0, yearThreeStart);

      expect(change.effectiveDate, yearTwoStart);
      expect(
        loan.outstandingDueAt(threeYearDate, forSettlement: false),
        closeTo(156250.0, 0.01),
      );
      expect(change.adjustmentAmount, closeTo(-12750.0, 0.01));
    });

    test('Rate decrease on 4-year loan reprices years 2 through 4', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE_FOUR_YEAR_PAID_ONE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final yearTwoStart = loan.date.add(const Duration(days: 365));
      final fourYearDate = loan.date.add(const Duration(days: (365 * 4) - 1));

      loan.addPartialRepayment(30000.0, yearTwoStart, interestOnly: true);
      final change = loan.changeInterestRate(25.0, fourYearDate);

      expect(change.effectiveDate, yearTwoStart);
      expect(
        loan.outstandingDueAt(fourYearDate, forSettlement: false),
        closeTo(195312.50, 0.01),
      );
      expect(change.adjustmentAmount, closeTo(-24387.50, 0.01));
    });

    test('Rate decrease on 5-year loan reprices years 2 through 5', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE_FIVE_YEAR_PAID_ONE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final yearTwoStart = loan.date.add(const Duration(days: 365));
      final fiveYearDate = loan.date.add(const Duration(days: (365 * 5) - 1));

      loan.addPartialRepayment(30000.0, yearTwoStart, interestOnly: true);
      final change = loan.changeInterestRate(25.0, fiveYearDate);

      expect(change.effectiveDate, yearTwoStart);
      expect(
        loan.outstandingDueAt(fiveYearDate, forSettlement: false),
        closeTo(244140.625, 0.01),
      );
      expect(change.adjustmentAmount, closeTo(-41469.375, 0.01));
    });

    test('Rate decrease with no paid interest reprices all elapsed periods', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE_NO_PAID_YEARS',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final threeYearDate = loan.date.add(const Duration(days: (365 * 3) - 1));
      final change = loan.changeInterestRate(25.0, threeYearDate);

      expect(change.effectiveDate, loan.date);
      expect(
        loan.outstandingDueAt(threeYearDate, forSettlement: false),
        closeTo(195312.50, 0.01),
      );
      expect(change.adjustmentAmount, closeTo(-24387.50, 0.01));
    });

    test('Rate decrease after two paid years reprices only year 3', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_DECREASE_TWO_PAID_YEARS',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final yearTwoStart = loan.date.add(const Duration(days: 365));
      final yearThreeStart = loan.date.add(const Duration(days: 730));
      final threeYearDate = loan.date.add(const Duration(days: (365 * 3) - 1));

      loan.addPartialRepayment(30000.0, yearTwoStart, interestOnly: true);
      loan.addPartialRepayment(30000.0, yearThreeStart, interestOnly: true);
      final change = loan.changeInterestRate(25.0, threeYearDate);

      expect(change.effectiveDate, yearThreeStart);
      expect(
        loan.outstandingDueAt(threeYearDate, forSettlement: false),
        closeTo(125000.0, 0.01),
      );
      expect(change.adjustmentAmount, closeTo(-5000.0, 0.01));
    });

    test('Saved rate-change records preserve selected effective date', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 25.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_SAVED_LATE_RATE_CHANGE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      final paidThroughDate = loan.date.add(const Duration(days: 365));
      final yearThreeStart = loan.date.add(const Duration(days: 730));
      final threeYearDate = loan.date.add(const Duration(days: (365 * 3) - 1));

      loan.addPartialRepayment(30000.0, paidThroughDate, interestOnly: true);
      loan.interestRateChanges.add(
        InterestRateChange(
          previousRate: 30.0,
          newRate: 25.0,
          effectiveDate: yearThreeStart,
          createdAt: threeYearDate,
          previousCalculatedDue: 169000.0,
          recalculatedDue: 162500.0,
          adjustmentAmount: -6500.0,
        ),
      );

      expect(
        loan.outstandingDueAt(threeYearDate, forSettlement: false),
        closeTo(162500.0, 0.01),
      );
    });

    test('Rate increase preserves paid previous year before compounding', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 25.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_INCREASE_PAID_YEAR',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.addPartialRepayment(
        25000.0,
        loan.date.add(const Duration(days: 365)),
        interestOnly: true,
      );
      final change = loan.changeInterestRate(
        30.0,
        loan.date.add(const Duration(days: (365 * 3) - 1)),
      );

      expect(change.effectiveDate, loan.date.add(const Duration(days: 365)));
      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 2) - 1)),
          forSettlement: false,
        ),
        closeTo(130000.0, 0.01),
      );
      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 3) - 1)),
          forSettlement: false,
        ),
        closeTo(169000.0, 0.01),
      );
    });

    test('Rate increase recalculates unpaid overdue years sequentially', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 25.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_RATE_INCREASE',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.changeInterestRate(30.0, loan.date.add(const Duration(days: 365)));

      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 3) - 1)),
          forSettlement: false,
        ),
        closeTo(211250.0, 0.01),
      );
      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 4) - 1)),
          forSettlement: false,
        ),
        closeTo(274625.0, 0.01),
      );
    });

    test('Multiple rate changes apply by effective date', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 30.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST_MULTIPLE_RATE_CHANGES',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      loan.changeInterestRate(25.0, loan.date.add(const Duration(days: 365)));
      loan.changeInterestRate(28.0, loan.date.add(const Duration(days: 730)));

      expect(
        loan.outstandingDueAt(
          loan.date.add(const Duration(days: (365 * 3) - 1)),
          forSettlement: false,
        ),
        closeTo(208000.0, 0.01),
      );
    });

    test('Partial repayment with annual interest rate', () {
      // Test partial repayment with annual interest rate
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 100,
        interestRate: 36.5, // 36.5% annual (0.1% daily)
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST004',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      // Add partial repayment of 50,000 after 50 days
      loan.addPartialRepayment(
        50000.0,
        DateTime(2024, 2, 20),
      ); // 50 days after loan

      // Calculate expected interest with daily rate (36.5/365 = 0.1%):
      // First 50 days: (100,000 * 0.1% * 50) / 100 = 5,000
      // Remaining 50 days: (50,000 * 0.1% * 50) / 100 = 2,500
      // Total: 7,500
      final dailyRate = 36.5 / 365;
      final expectedInterest =
          (100000.0 * dailyRate * 50) / 100 + (50000.0 * dailyRate * 50) / 100;
      final actualInterest = loan.calculatedInterest;

      expect(actualInterest, closeTo(expectedInterest, 0.01));
    });

    test('Multiple partial repayments with annual rate', () {
      // Test multiple partial repayments with annual interest rate
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 90,
        interestRate: 73.0, // 73% annual (0.2% daily)
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST005',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 100000.0,
      );

      // Add multiple partial repayments
      loan.addPartialRepayment(
        30000.0,
        DateTime(2024, 1, 31),
      ); // 30 days
      loan.addPartialRepayment(
        20000.0,
        DateTime(2024, 2, 29),
      ); // 29 days from Jan 31
      // Remaining 31 days (90 - 30 - 29 = 31)

      // Calculate with daily rate (73/365 = 0.2%)
      final dailyRate = 73.0 / 365;
      final expectedInterest =
          (100000.0 * dailyRate * 30) / 100 +   // First period: 30 days
          (70000.0 * dailyRate * 29) / 100 +    // Second period: 29 days
          (50000.0 * dailyRate * 31) / 100;     // Third period: 31 days
      final actualInterest = loan.calculatedInterest;

      expect(actualInterest, closeTo(expectedInterest, 0.01));
    });
  });
}
