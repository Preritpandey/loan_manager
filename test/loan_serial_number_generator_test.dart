import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';
import 'package:list/utils/loan_serial_number_generator.dart';

Loan _loan(String name, String serialNumber) {
  return Loan(
    name: name,
    date: DateTime(2026, 1, 1),
    duration: 365,
    interestRate: 12,
    type: 'Gold',
    jewelleryName: 'Ring',
    serialNumber: serialNumber,
    phone: '0000000000',
    address: 'Address',
    description: '',
    amountGiven: 1000,
  );
}

void main() {
  test('creates the requested customer serial format and sequence', () {
    final existingLoans = [
      _loan('Chaudhary Jewellers', 'ch-jw01'),
      _loan('Chaudhary Jewellers', 'old-manual-serial'),
    ];

    expect(
      LoanSerialNumberGenerator.generate(
        customerName: 'Chaudhary Jewellers',
        existingLoans: existingLoans,
      ),
      'ch-jw03',
    );
  });

  test('does not depend on existing manual serial values', () {
    expect(
      LoanSerialNumberGenerator.generate(
        customerName: 'John Doe',
        existingLoans: [_loan('John Doe', 'legacy-serial')],
      ),
      'jo-do02',
    );
  });
}
