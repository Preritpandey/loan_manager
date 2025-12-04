import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';

// Helper class to make Loan class testable with custom dates
class TestableLoan extends Loan {
  DateTime currentDate;

  TestableLoan({
    required String name,
    required DateTime date,
    required int duration,
    required double interestRate,
    required String type,
    required String jewelleryName,
    required String serialNumber,
    required String phone,
    required String address,
    required String description,
    required double amountGiven,
    required this.currentDate,
  }) : super(
         name: name,
         date: date,
         duration: duration,
         interestRate: interestRate,
         type: type,
         jewelleryName: jewelleryName,
         serialNumber: serialNumber,
         phone: phone,
         address: address,
         description: description,
         amountGiven: amountGiven,
       );

  @override
  int get daysPassed => currentDate.difference(date).inDays;

  @override
  int get overdueDays {
    final daysPassed = currentDate.difference(date).inDays;
    return daysPassed > duration ? daysPassed - duration : 0;
  }

  @override
  bool get isFullyPaid {
    // Calculate the total amount that should be paid by now
    final totalDue = outstandingDueAt(currentDate, forSettlement: false);
    // Consider the loan fully paid if the remaining amount is very small (floating point precision)
    return totalDue <= 0.01;
  }
}

void main() {
  group('Loan Overdue Status Tests', () {
    late TestableLoan loan;
    final today = DateTime(
      2024,
      1,
      1,
    ); // Fixed reference date for consistent testing

    setUp(() {
      loan = TestableLoan(
        name: 'Test Customer',
        date: today.subtract(
          const Duration(days: 30),
        ), // Loan started 30 days ago
        duration: 30, // 30-day loan
        interestRate: 20.0,
        type: 'Gold',
        jewelleryName: 'Gold Chain',
        serialNumber: 'TEST001',
        phone: '1234567890',
        address: 'Test Address',
        description: 'Test Description',
        amountGiven: 10000.0,
        currentDate: today, // Current date is the same as today initially
      );
    });

    test('Loan should be overdue after due date', () {
      // Set current date to 35 days after loan start (5 days overdue)
      loan.currentDate = loan.date.add(const Duration(days: 35));

      expect(loan.isOverdue, isTrue);
      expect(loan.overdueDays, 5);
    });

    test('Paid loan should not become overdue again', () {
      // First, make the loan overdue
      final overdueDate = loan.date.add(const Duration(days: 35));
      loan.currentDate = overdueDate;

      // Verify loan is overdue
      expect(loan.isOverdue, isTrue);

      // Pay the full amount (principal + interest)
      final amountToPay = loan.outstandingDueAt(
        overdueDate,
        forSettlement: false,
      );
      loan.addPartialRepayment(amountToPay, overdueDate);

      // Create a new loan instance to simulate a fresh state
      final paidLoan = TestableLoan(
        name: loan.name,
        date: loan.date,
        duration: loan.duration,
        interestRate: loan.interestRate,
        type: loan.type,
        jewelleryName: loan.jewelleryName,
        serialNumber: loan.serialNumber,
        phone: loan.phone,
        address: loan.address,
        description: loan.description,
        amountGiven: loan.amountGiven,
        currentDate: overdueDate.add(
          const Duration(days: 10),
        ), // Fast forward 10 days
      )..addPartialRepayment(amountToPay, overdueDate);

      // Verify loan is not overdue after payment and time passes
      expect(paidLoan.isOverdue, isFalse);
      expect(paidLoan.overdueDays, 0);
    });

    test('Partially paid loan should still be marked as overdue', () {
      // Make the loan overdue
      final overdueDate = loan.date.add(const Duration(days: 35));
      loan.currentDate = overdueDate;

      // Verify loan is overdue
      expect(loan.isOverdue, isTrue);

      // Pay only part of the amount (less than the full due)
      final partialAmount = 5000.0;
      loan.addPartialRepayment(partialAmount, overdueDate);

      // Verify loan is still overdue
      expect(loan.isOverdue, isTrue);
      expect(loan.isFullyPaid, isFalse);

      // Fast forward 10 more days
      loan.currentDate = overdueDate.add(const Duration(days: 10));

      // Verify loan is still overdue
      expect(loan.isOverdue, isTrue);
      expect(loan.overdueDays, 15); // 35 + 10 - 30 days
    });
  });
}
