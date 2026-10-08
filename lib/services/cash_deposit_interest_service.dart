import 'package:list/models/deposit.dart';
import 'package:list/utils/nepali_date_utils.dart';

class CashDepositInterestService {
  List<DepositTransaction> processMaturedDeposits(
    DepositModel deposit, {
    NepaliDate? asOf,
  }) {
    final effectiveDate = asOf ?? NepaliDate.today();
    final generated = <DepositTransaction>[];
    final updatedLots = List<CashDepositLot>.from(deposit.lots);

    for (var i = 0; i < updatedLots.length; i++) {
      final lot = updatedLots[i];
      lot.status = lot.statusFor(effectiveDate);
      if (lot.interestApplied || !lot.isMaturedOn(effectiveDate)) {
        updatedLots[i] = lot;
        continue;
      }
      if (lot.remainingPrincipal <= 0) {
        lot.interestApplied = true;
        lot.status = 'Fully Withdrawn';
        updatedLots[i] = lot;
        continue;
      }

      final interest = calculateInterest(lot);
      lot.acquiredInterest += interest;
      lot.remainingInterest += interest;
      lot.interestApplied = true;
      lot.status = lot.statusFor(effectiveDate);
      updatedLots[i] = lot;

      final principalAfter = updatedLots.fold<double>(
        0,
        (sum, item) => sum + item.remainingPrincipal,
      );
      final interestAfter = updatedLots.fold<double>(
        0,
        (sum, item) => sum + item.remainingInterest,
      );
      generated.add(
        DepositTransaction(
          type: 'Interest Applied',
          source: 'Interest Applied',
          amount: interest,
          dateNepali: effectiveDate.format(),
          description:
              'Interest for ${lot.depositDate} lot at ${lot.interestRate}%',
          balanceAfter: principalAfter + interestAfter,
          principalBalanceAfter: principalAfter,
          interestBalanceAfter: interestAfter,
          totalBalanceAfter: principalAfter + interestAfter,
          lotId: lot.id,
        ),
      );
    }

    deposit.lots = updatedLots;
    if (generated.isNotEmpty) {
      deposit.transactions = List<DepositTransaction>.from(deposit.transactions)
        ..addAll(generated);
    }
    return generated;
  }

  double calculateInterest(CashDepositLot lot) {
    return (lot.remainingPrincipal * lot.interestRate) / 100;
  }

  List<CashDepositLot> maturedLots(DepositModel deposit, {NepaliDate? asOf}) {
    final effectiveDate = asOf ?? NepaliDate.today();
    return deposit.lots
        .where(
          (lot) =>
              !lot.interestApplied &&
              lot.remainingPrincipal > 0 &&
              lot.isMaturedOn(effectiveDate),
        )
        .toList();
  }
}
