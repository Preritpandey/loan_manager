import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/loan.dart';
import 'package:list/utils/loan_serial_number_generator.dart';

Loan _loan(String name, String serialNumber, {int day = 1}) {
  return Loan(
    name: name,
    date: DateTime(2026, 1, day),
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
  group('parseSerial', () {
    test('extracts useful parts from supported historical formats', () {
      final slash = LoanSerialNumberGenerator.parseSerial(
        '421/gautam chaudhary',
      );
      expect(slash.valid, isTrue);
      expect(slash.number, 421);
      expect(slash.prefix, '');
      expect(slash.separator, '/');
      expect(slash.name, 'gautam chaudhary');

      final pls = LoanSerialNumberGenerator.parseSerial('PLS00942 Kabita Rai');
      expect(pls.valid, isTrue);
      expect(pls.number, 942);
      expect(pls.prefix, 'PLS');
      expect(pls.separator, ' ');
      expect(pls.name, 'Kabita Rai');

      final generated = LoanSerialNumberGenerator.parseSerial('MA-JE-03');
      expect(generated.valid, isTrue);
      expect(generated.number, 3);
      expect(generated.prefix, 'MA-JE');
      expect(generated.separator, '-');
    });

    test('ignores malformed and pseudo serial numbers', () {
      for (final serial in ['000', '0000000000000', 'ONJK00044', 'KB', 'XXX']) {
        expect(LoanSerialNumberGenerator.parseSerial(serial).valid, isFalse);
      }
    });
  });

  group('historical customer formats', () {
    test('continues new kuwer jeweels slash format', () {
      final loans = [
        _loan('new kuwer jeweels', '420/gautam chaudhary'),
        _loan('new kuwer jeweels', '421/gautam chaudhary'),
      ];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'new kuwer jeweels',
          borrowerName: 'Ganga Devi',
          existingLoans: loans,
        ),
        '422/Ganga Devi',
      );
    });

    test('continues pathivara silver PLS five digit format', () {
      final loans = [
        _loan('NEW PATHIVARA SLIVER', 'PLS00940 Ram Thapa'),
        _loan('NEW PATHIVARA SLIVER', 'PLS00941 Sita Thapa'),
        _loan('NEW PATHIVARA SLIVER', 'PLS00942 Kabita Rai'),
      ];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'NEW PATHIVARA SLIVER',
          borrowerName: 'Sita Thapa',
          existingLoans: loans,
        ),
        'PLS00943 Sita Thapa',
      );
    });

    test('continues pathivara gold lowercase pl format', () {
      final loans = [
        _loan('NEW PATHIVARA GOLD', 'pl2006 Ram Thapa'),
        _loan('NEW PATHIVARA GOLD', 'pl2007/Sita Thapa'),
        _loan('NEW PATHIVARA GOLD', 'pl2008 Ramesh Thapa'),
      ];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'NEW PATHIVARA GOLD',
          borrowerName: 'Hari Rai',
          existingLoans: loans,
        ),
        'pl2009 Hari Rai',
      );
    });

    test('uses max number across mixed slash and space formats', () {
      final loans = [
        _loan('khushi jwls', '789 sulav khawas'),
        _loan('khushi jwls', '790/sulav khawas'),
        _loan('khushi jwls', '000'),
      ];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'khushi jwls',
          borrowerName: 'Anita Chaudhary',
          existingLoans: loans,
        ),
        '791/Anita Chaudhary',
      );
    });

    test('continues chaudhary jewellers space format', () {
      final loans = [_loan('chaudhary jewellers', '41 Ram Thapa')];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'chaudhary jewellers',
          borrowerName: 'Sita Rai',
          existingLoans: loans,
        ),
        '42 Sita Rai',
      );
    });
  });

  group('new customer serials', () {
    test('generates a deterministic name based prefix and sequence', () {
      expect(
        LoanSerialNumberGenerator.generatePrefix('Mahalaxmi Jewellers'),
        'MA-JE',
      );

      final loans = [
        _loan('Mahalaxmi Jewellers', 'MA-JE-01'),
        _loan('Mahalaxmi Jewellers', 'MA-JE-02'),
        _loan('Mahalaxmi Jewellers', 'MA-JE-03'),
      ];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'Mahalaxmi Jewellers',
          existingLoans: loans,
        ),
        'MA-JE-04',
      );
    });

    test('uses configured custom prefix and padding for new customers', () {
      const configs = {
        'mahalaxmi jewellers': LoanSerialNumberConfig(
          customPrefix: 'MJ',
          padding: 3,
        ),
      };

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'Mahalaxmi Jewellers',
          existingLoans: [],
          configs: configs,
        ),
        'MJ-001',
      );
    });

    test('does not overwrite historical customers with name based prefixes', () {
      final loans = [_loan('new kuwer jeweels', '421/gautam chaudhary')];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'new kuwer jeweels',
          borrowerName: 'Ganga Devi',
          existingLoans: loans,
        ),
        isNot('NE-JE-01'),
      );
    });

    test('retries when a generated serial already exists elsewhere', () {
      final loans = [
        _loan('Other Customer', 'MA-JE-01'),
      ];

      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'Mahalaxmi Jewellers',
          existingLoans: loans,
        ),
        'MA-JE-02',
      );
    });

    test('excludes special customers from automatic numbering', () {
      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'BAAKI',
          existingLoans: [_loan('BAAKI', '000001')],
        ),
        '',
      );
      expect(
        LoanSerialNumberGenerator.generate(
          customerName: 'examle',
          existingLoans: [],
        ),
        '',
      );
    });
  });
}
