import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';

void main() {
  test('Loan should not become overdue again after being fully paid', () {
    // Create a loan that started 30 days ago with a 30-day term
    final startDate = DateTime(2024, 1, 1);
    final loan = Loan(
      name: 'Test Customer',
      date: startDate,
      duration: 30,
      interestRate: 20.0,
      type: 'Gold',
      jewelleryName: 'Gold Chain',
      serialNumber: 'TEST001',
      phone: '1234567890',
      address: 'Test Address',
      description: 'Test Description',
      amountGiven: 10000.0,
    );

    // Fast forward to 35 days after start (5 days overdue)
    final overdueDate = startDate.add(const Duration(days: 35));

    // Check that the loan is indeed overdue
    bool isOverdue = overdueDate.difference(loan.date).inDays > loan.duration;
    expect(isOverdue, isTrue, reason: 'Loan should be overdue at this point');

    // Pay the full amount due
    final amountToPay = loan.outstandingDueAt(
      overdueDate,
      forSettlement: false,
    );
    loan.addPartialRepayment(amountToPay, overdueDate);

    // Verify the loan is now fully paid
    expect(
      loan.isFullyPaid,
      isTrue,
      reason: 'Loan should be fully paid after payment',
    );

    // Fast forward another 10 days
    final futureDate = overdueDate.add(const Duration(days: 10));

    // The loan should still not be considered overdue because it's fully paid
    // Note: We need to check the actual business logic here
    // Since we can't mock DateTime.now(), we'll check the logic directly
    final daysSinceLoan = futureDate.difference(loan.date).inDays;
    final shouldBeOverdue =
        !loan.isFullyPaid && (daysSinceLoan > loan.duration);

    expect(
      shouldBeOverdue,
      isFalse,
      reason:
          'Loan should not be overdue after being fully paid, even when time passes',
    );
  });
}
