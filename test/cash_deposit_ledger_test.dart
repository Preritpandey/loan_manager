import 'package:flutter_test/flutter_test.dart';
import 'package:list/models/deposit.dart';
import 'package:list/services/cash_deposit_interest_service.dart';
import 'package:list/utils/nepali_date_utils.dart';

void main() {
  group('Cash deposit ledger', () {
    test('deposit creation creates an independent lot with maturity date', () {
      final deposit = _deposit();

      deposit.addDepositLot(
        amount: 100000,
        nepaliDateString: '2083 Baisakh 20',
        rate: 20,
      );

      expect(deposit.lots, hasLength(1));
      expect(deposit.totalPrincipal, 100000);
      expect(deposit.acquiredInterest, 0);
      expect(deposit.lots.first.maturityDate, '2084 Baisakh 20');
    });

    test('not yet matured deposit does not generate interest', () {
      final deposit = _deposit()
        ..addDepositLot(
          amount: 100000,
          nepaliDateString: '2083 Baisakh 20',
          rate: 20,
        );

      final generated = CashDepositInterestService().processMaturedDeposits(
        deposit,
        asOf: NepaliDate(year: 2084, month: 1, day: 19),
      );

      expect(generated, isEmpty);
      expect(deposit.acquiredInterest, 0);
    });

    test('matured deposit calculates interest from remaining principal', () {
      final deposit = _deposit()
        ..addDepositLot(
          amount: 100000,
          nepaliDateString: '2083 Baisakh 20',
          rate: 20,
        );
      deposit.withdrawPrincipal(
        amount: 20000,
        nepaliDateString: '2083 Jestha 1',
      );

      CashDepositInterestService().processMaturedDeposits(
        deposit,
        asOf: NepaliDate(year: 2084, month: 1, day: 20),
      );

      expect(deposit.totalPrincipal, 80000);
      expect(deposit.acquiredInterest, 16000);
      expect(deposit.totalAmountOwed, 96000);
    });

    test('additional deposits mature independently', () {
      final deposit = _deposit()
        ..addDepositLot(
          amount: 100000,
          nepaliDateString: '2083 Baisakh 20',
          rate: 20,
        )
        ..addDepositLot(
          amount: 40000,
          nepaliDateString: '2083 Shrawan 18',
          rate: 20,
        );
      final service = CashDepositInterestService();

      service.processMaturedDeposits(
        deposit,
        asOf: NepaliDate(year: 2084, month: 1, day: 20),
      );
      expect(deposit.totalPrincipal, 140000);
      expect(deposit.acquiredInterest, 20000);
      expect(deposit.totalAmountOwed, 160000);

      service.processMaturedDeposits(
        deposit,
        asOf: NepaliDate(year: 2084, month: 4, day: 18),
      );
      expect(deposit.totalPrincipal, 140000);
      expect(deposit.acquiredInterest, 28000);
      expect(deposit.totalAmountOwed, 168000);
    });

    test('principal withdrawals allocate largest deposit first', () {
      final deposit = _deposit()
        ..addDepositLot(
          amount: 100000,
          nepaliDateString: '2083 Baisakh 20',
          rate: 20,
        )
        ..addDepositLot(
          amount: 40000,
          nepaliDateString: '2083 Shrawan 18',
          rate: 20,
        )
        ..addDepositLot(
          amount: 30000,
          nepaliDateString: '2083 Mangsir 1',
          rate: 20,
        );

      deposit.withdrawPrincipal(
        amount: 130000,
        nepaliDateString: '2083 Poush 1',
      );

      expect(deposit.lots[0].remainingPrincipal, 0);
      expect(deposit.lots[1].remainingPrincipal, 10000);
      expect(deposit.lots[2].remainingPrincipal, 30000);
    });

    test('interest withdrawal does not reduce principal', () {
      final deposit = _deposit()
        ..addDepositLot(
          amount: 100000,
          nepaliDateString: '2083 Baisakh 20',
          rate: 20,
        );
      CashDepositInterestService().processMaturedDeposits(
        deposit,
        asOf: NepaliDate(year: 2084, month: 1, day: 20),
      );

      deposit.withdrawInterest(
        amount: 5000,
        nepaliDateString: '2084 Jestha 1',
      );

      expect(deposit.totalPrincipal, 100000);
      expect(deposit.acquiredInterest, 15000);
      expect(deposit.totalAmountOwed, 115000);
    });

    test('interest processing is idempotent', () {
      final deposit = _deposit()
        ..addDepositLot(
          amount: 100000,
          nepaliDateString: '2083 Baisakh 20',
          rate: 20,
        );
      final service = CashDepositInterestService();
      final asOf = NepaliDate(year: 2084, month: 1, day: 20);

      service.processMaturedDeposits(deposit, asOf: asOf);
      service.processMaturedDeposits(deposit, asOf: asOf);

      expect(deposit.acquiredInterest, 20000);
      expect(
        deposit.transactions.where((txn) => txn.type == 'Interest Applied'),
        hasLength(1),
      );
    });
  });
}

DepositModel _deposit() {
  return DepositModel(
    name: 'Customer',
    address: 'Kathmandu',
    phone: '9800000000',
    interestRate: 20,
  );
}
