import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';

void main() {
  group('Custom Days Calculation Tests', () {
    test('Custom days interest calculation with 20% annual rate', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 100, // Original agreed duration
        interestRate: 20.0, // 20% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST001',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // Test custom days calculation for 150 days
      final customDays = 150;
      final customInterest = loan.calculateCustomDaysInterest(customDays);
      final customTotal = loan.calculateCustomDaysTotal(customDays);

      // Expected calculation:
      // Daily rate = 20% / 365 = 0.05479%
      // Interest = (10,000 × 0.05479% × 150) / 100 = 821.92
      // Total = 10,000 + 821.92 = 10,821.92
      final expectedDailyRate = 20.0 / 365;
      final expectedInterest = (10000.0 * expectedDailyRate * customDays) / 100;
      final expectedTotal = 10000.0 + expectedInterest;

      expect(customInterest, closeTo(expectedInterest, 0.01));
      expect(customTotal, closeTo(expectedTotal, 0.01));
      expect(customInterest, closeTo(821.92, 0.01));
      expect(customTotal, closeTo(10821.92, 0.01));
    });

    test('Custom days calculation for different periods', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 365,
        interestRate: 36.5, // 36.5% annual (0.1% daily)
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST002',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 50000.0,
      );

      // Test for 30 days
      final interest30Days = loan.calculateCustomDaysInterest(30);
      final total30Days = loan.calculateCustomDaysTotal(30);
      
      // Expected: (50,000 × 0.1% × 30) / 100 = 1,500
      expect(interest30Days, closeTo(1500.0, 0.01));
      expect(total30Days, closeTo(51500.0, 0.01));

      // Test for 365 days (full year)
      final interest365Days = loan.calculateCustomDaysInterest(365);
      final total365Days = loan.calculateCustomDaysTotal(365);
      
      // Expected: (50,000 × 36.5% × 365) / (365 × 100) = 18,250
      expect(interest365Days, closeTo(18250.0, 0.01));
      expect(total365Days, closeTo(68250.0, 0.01));
    });

    test('Custom days calculation for zero days', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 100,
        interestRate: 25.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST003',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 15000.0,
      );

      // Test for 0 days
      final interest0Days = loan.calculateCustomDaysInterest(0);
      final total0Days = loan.calculateCustomDaysTotal(0);
      
      expect(interest0Days, equals(0.0));
      expect(total0Days, equals(15000.0)); // Should equal principal
    });

    test('Custom days calculation matches original agreed period', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 90, // Agreed duration
        interestRate: 30.0, // 30% annual
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST004',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 25000.0,
      );

      // Custom calculation for agreed period should match agreed period interest
      final customInterest = loan.calculateCustomDaysInterest(loan.duration);
      final agreedInterest = loan.agreedPeriodInterest;
      
      expect(customInterest, closeTo(agreedInterest, 0.01));
    });

    test('Daily rate consistency across calculations', () {
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 60,
        interestRate: 18.25, // 18.25% annual (0.05% daily)
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST005',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 8000.0,
      );

      // Daily rate should be consistent
      final expectedDailyRate = 18.25 / 365;
      expect(loan.dailyInterestRate, closeTo(expectedDailyRate, 0.0001));
      
      // Custom calculation should use the same daily rate
      final customInterest = loan.calculateCustomDaysInterest(45);
      final expectedInterest = (8000.0 * expectedDailyRate * 45) / 100;
      
      expect(customInterest, closeTo(expectedInterest, 0.01));
    });
  });
}