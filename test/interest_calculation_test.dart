import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';

void main() {
  group('Interest Calculation Tests', () {
    test('Minimum one-month interest rule for loans up to 30 days', () {
      // Test case 1: 20-day loan
      final loan20Days = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 20,
        interestRate: 2.0, // 2% per day
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST001',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // After 15 days, should still charge for 30 days (minimum one month)
      final testDate = DateTime(2024, 1, 16); // 15 days after loan
      final daysPassed = testDate.difference(loan20Days.date).inDays;

      // Should calculate interest for 30 days (minimum) not 15 days
      final expectedInterest = (10000.0 * 2.0 / 100) * 30; // 30 days minimum
      final actualInterest = loan20Days.calculatedInterest;

      expect(actualInterest, equals(expectedInterest));
    });

    test('Daily interest for loans longer than 30 days', () {
      // Test case 2: 60-day loan
      final loan60Days = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 60,
        interestRate: 2.0, // 2% per day
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST002',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // After 35 days, should charge for exactly 35 days
      final testDate = DateTime(2024, 2, 5); // 35 days after loan
      final daysPassed = testDate.difference(loan60Days.date).inDays;

      // Should calculate interest for exactly 35 days
      final expectedInterest = (10000.0 * 2.0 / 100) * 35;
      final actualInterest = loan60Days.calculatedInterest;

      expect(actualInterest, equals(expectedInterest));
    });

    test('Early repayment adjustment', () {
      // Test case 3: 200-day loan repaid early
      final loan200Days = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 200,
        interestRate: 2.0, // 2% per day
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST003',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
      );

      // After 100 days (early repayment), should charge for exactly 100 days
      final testDate = DateTime(2024, 4, 10); // 100 days after loan
      final daysPassed = testDate.difference(loan200Days.date).inDays;

      // Should calculate interest for exactly 100 days, not 200 days
      final expectedInterest = (10000.0 * 2.0 / 100) * 100;
      final actualInterest = loan200Days.calculatedInterest;

      expect(actualInterest, equals(expectedInterest));
    });

    test('Partial repayment reduces interest calculation', () {
      // Test case 4: Partial repayment scenario
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 100,
        interestRate: 2.0, // 2% per day
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

      // Calculate expected interest:
      // First 50 days: 100,000 * 2% * 50 = 100,000
      // Remaining 50 days: 50,000 * 2% * 50 = 50,000
      // Total: 150,000
      final expectedInterest =
          (100000.0 * 2.0 / 100) * 50 + (50000.0 * 2.0 / 100) * 50;
      final actualInterest = loan.calculatedInterest;

      expect(actualInterest, equals(expectedInterest));
    });

    test('Multiple partial repayments', () {
      // Test case 5: Multiple partial repayments
      final loan = Loan(
        name: 'Test Customer',
        date: DateTime(2024, 1, 1),
        duration: 90,
        interestRate: 2.0, // 2% per day
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
      ); // 30 days: 100,000 * 2% * 30 = 60,000
      loan.addPartialRepayment(
        20000.0,
        DateTime(2024, 2, 29),
      ); // 30 days: 70,000 * 2% * 30 = 42,000
      // Remaining 30 days: 50,000 * 2% * 30 = 30,000
      // Total: 60,000 + 42,000 + 30,000 = 132,000

      final expectedInterest =
          (100000.0 * 2.0 / 100) * 30 +
          (70000.0 * 2.0 / 100) * 30 +
          (50000.0 * 2.0 / 100) * 30;
      final actualInterest = loan.calculatedInterest;

      expect(actualInterest, equals(expectedInterest));
    });
  });
}
