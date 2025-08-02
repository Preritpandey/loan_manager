import 'package:flutter_test/flutter_test.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';

void main() {
  group('Search Functionality Tests', () {
    late LoanController controller;

    setUp(() {
      controller = LoanController();
    });

    test('Search by customer name should work', () {
      // Add test loans
      final loan1 = Loan(
        name: 'John Doe',
        serialNumber: 'SN001',
        phone: '1234567890',
        jewelleryName: 'Gold Ring',
        amountGiven: 1000,
        interestRate: 5,
        duration: 30,
        date: DateTime.now(),
        type: 'Gold',
        address: 'Test Address',
        description: 'Test Description',
      );

      final loan2 = Loan(
        name: 'Jane Smith',
        serialNumber: 'SN002',
        phone: '0987654321',
        jewelleryName: 'Silver Chain',
        amountGiven: 2000,
        interestRate: 5,
        duration: 30,
        date: DateTime.now(),
        type: 'Silver',
        address: 'Test Address',
        description: 'Test Description',
      );

      controller.addLoan(loan1);
      controller.addLoan(loan2);

      // Test search by name
      controller.search('John');
      expect(controller.getFilteredLoans().length, 1);
      expect(controller.getFilteredLoans().first.name, 'John Doe');

      // Test search by serial number
      controller.search('SN001');
      expect(controller.getFilteredLoans().length, 1);
      expect(controller.getFilteredLoans().first.serialNumber, 'SN001');

      // Test search by phone
      controller.search('1234567890');
      expect(controller.getFilteredLoans().length, 1);
      expect(controller.getFilteredLoans().first.phone, '1234567890');

      // Test search by jewellery name
      controller.search('Gold');
      expect(controller.getFilteredLoans().length, 1);
      expect(controller.getFilteredLoans().first.jewelleryName, 'Gold Ring');

      // Test empty search
      controller.search('');
      expect(controller.getFilteredLoans().length, 2);
    });

    test('Search should be case insensitive', () {
      final loan = Loan(
        name: 'John Doe',
        serialNumber: 'SN001',
        phone: '1234567890',
        jewelleryName: 'Gold Ring',
        amountGiven: 1000,
        interestRate: 5,
        duration: 30,
        date: DateTime.now(),
        type: 'Gold',
        address: 'Test Address',
        description: 'Test Description',
      );

      controller.addLoan(loan);

      // Test case insensitive search
      controller.search('john');
      expect(controller.getFilteredLoans().length, 1);

      controller.search('GOLD');
      expect(controller.getFilteredLoans().length, 1);
    });

    test('Search should return all loans when query is empty', () {
      final loan1 = Loan(
        name: 'John Doe',
        serialNumber: 'SN001',
        phone: '1234567890',
        jewelleryName: 'Gold Ring',
        amountGiven: 1000,
        interestRate: 5,
        duration: 30,
        date: DateTime.now(),
        type: 'Gold',
        address: 'Test Address',
        description: 'Test Description',
      );

      final loan2 = Loan(
        name: 'Jane Smith',
        serialNumber: 'SN002',
        phone: '0987654321',
        jewelleryName: 'Silver Chain',
        amountGiven: 2000,
        interestRate: 5,
        duration: 30,
        date: DateTime.now(),
        type: 'Silver',
        address: 'Test Address',
        description: 'Test Description',
      );

      controller.addLoan(loan1);
      controller.addLoan(loan2);

      controller.search('');
      expect(controller.getFilteredLoans().length, 2);
    });
  });
}
