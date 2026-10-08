import 'package:hive/hive.dart';
import 'package:list/utils/nepali_date_utils.dart';

@HiveType(typeId: 11)
class CashDepositLot extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String customerId;

  @HiveField(2)
  double originalAmount;

  @HiveField(3)
  double remainingPrincipal;

  @HiveField(4)
  String depositDate;

  @HiveField(5)
  String maturityDate;

  @HiveField(6)
  double interestRate;

  @HiveField(7)
  double acquiredInterest;

  @HiveField(8)
  double remainingInterest;

  @HiveField(9)
  String status;

  @HiveField(10)
  bool interestApplied;

  CashDepositLot({
    String? id,
    required this.customerId,
    required this.originalAmount,
    required this.remainingPrincipal,
    required this.depositDate,
    required this.maturityDate,
    required this.interestRate,
    this.acquiredInterest = 0,
    this.remainingInterest = 0,
    this.status = 'Not Matured',
    this.interestApplied = false,
  }) : id = id ?? 'lot_${DateTime.now().microsecondsSinceEpoch}';

  bool get isFullyWithdrawn => remainingPrincipal <= 0.0001;

  bool isMaturedOn(NepaliDate asOf) {
    final maturity = NepaliDate.parse(maturityDate);
    if (maturity == null) return false;
    return maturity.toGregorian().compareTo(asOf.toGregorian()) <= 0;
  }

  String statusFor(NepaliDate asOf) {
    if (isFullyWithdrawn) return 'Fully Withdrawn';
    if (remainingPrincipal < originalAmount) return 'Partially Withdrawn';
    if (!interestApplied && isMaturedOn(asOf)) return 'Interest Eligible';
    return 'Not Matured';
  }
}

@HiveType(typeId: 3)
class DepositTransaction extends HiveObject {
  @HiveField(0)
  String type;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String dateNepali;

  @HiveField(3)
  String? description;

  @HiveField(4)
  double balanceAfter;

  @HiveField(5)
  DateTime? dateAD;

  @HiveField(6)
  String? source;

  @HiveField(7)
  String? lotId;

  @HiveField(8)
  double principalBalanceAfter;

  @HiveField(9)
  double interestBalanceAfter;

  @HiveField(10)
  double totalBalanceAfter;

  DepositTransaction({
    required this.type,
    required this.amount,
    required this.dateNepali,
    this.description,
    required this.balanceAfter,
    DateTime? dateAD,
    this.source,
    this.lotId,
    double? principalBalanceAfter,
    double? interestBalanceAfter,
    double? totalBalanceAfter,
  })  : dateAD = dateAD ?? NepaliDate.parse(dateNepali)?.toGregorian(),
        principalBalanceAfter = principalBalanceAfter ?? balanceAfter,
        interestBalanceAfter = interestBalanceAfter ?? 0,
        totalBalanceAfter = totalBalanceAfter ?? balanceAfter;
}

@HiveType(typeId: 2)
class DepositModel extends HiveObject {
  @HiveField(0)
  String depositId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  String phone;

  @HiveField(4)
  double interestRate;

  @HiveField(5)
  String? description;

  @HiveField(6)
  List<DepositTransaction> transactions;

  @HiveField(7)
  List<CashDepositLot> lots;

  DepositModel({
    String? depositId,
    required this.name,
    required this.address,
    required this.phone,
    required this.interestRate,
    this.description,
    List<DepositTransaction>? transactions,
    List<CashDepositLot>? lots,
  })  : depositId = depositId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        transactions = transactions ?? [],
        lots = lots ?? [];

  double get totalPrincipal =>
      lots.fold(0.0, (sum, lot) => sum + lot.remainingPrincipal);

  double get acquiredInterest =>
      lots.fold(0.0, (sum, lot) => sum + lot.remainingInterest);

  double get totalAmountOwed => totalPrincipal + acquiredInterest;

  double get currentBalance {
    if (lots.isNotEmpty) return totalAmountOwed;
    if (transactions.isEmpty) return 0.0;
    return transactions.last.balanceAfter;
  }

  String get latestTransactionDateNepali {
    if (transactions.isEmpty) return '-';
    return transactions.last.dateNepali;
  }

  List<CashDepositLot> get lotsSortedDesc {
    final list = List<CashDepositLot>.from(lots);
    list.sort((a, b) {
      final adA = NepaliDate.parse(a.depositDate)?.toGregorian();
      final adB = NepaliDate.parse(b.depositDate)?.toGregorian();
      if (adA == null && adB == null) return 0;
      if (adA == null) return 1;
      if (adB == null) return -1;
      return adB.compareTo(adA);
    });
    return list;
  }

  void addTransaction({
    required String type,
    required double amount,
    required String nepaliDateString,
    String? description,
  }) {
    if (type == 'Deposit') {
      addDepositLot(
        amount: amount,
        nepaliDateString: nepaliDateString,
        rate: interestRate,
        description: description,
      );
      return;
    }
    if (type == 'Withdrawal') {
      withdrawPrincipal(
        amount: amount,
        nepaliDateString: nepaliDateString,
        description: description,
      );
      return;
    }
    throw ArgumentError('Invalid transaction type: $type');
  }

  CashDepositLot addDepositLot({
    required double amount,
    required String nepaliDateString,
    required double rate,
    String? description,
  }) {
    final date = NepaliDate.parse(nepaliDateString);
    final maturity = date?.addYears(1).format() ?? nepaliDateString;
    final lot = CashDepositLot(
      customerId: depositId,
      originalAmount: amount,
      remainingPrincipal: amount,
      depositDate: nepaliDateString,
      maturityDate: maturity,
      interestRate: rate,
    );
    lots = List<CashDepositLot>.from(lots)..add(lot);
    transactions = List<DepositTransaction>.from(transactions)
      ..add(
        DepositTransaction(
          type: 'Deposit',
          source: 'Deposit',
          amount: amount,
          dateNepali: nepaliDateString,
          description: description,
          balanceAfter: totalAmountOwed,
          principalBalanceAfter: totalPrincipal,
          interestBalanceAfter: acquiredInterest,
          totalBalanceAfter: totalAmountOwed,
          lotId: lot.id,
        ),
      );
    return lot;
  }

  List<DepositWithdrawalAllocation> previewPrincipalWithdrawal(double amount) {
    var remaining = amount;
    final result = <DepositWithdrawalAllocation>[];
    final ordered = lots
        .where((lot) => lot.remainingPrincipal > 0)
        .toList()
      ..sort((a, b) {
        final amountCompare = b.originalAmount.compareTo(a.originalAmount);
        if (amountCompare != 0) return amountCompare;
        final aDate = NepaliDate.parse(a.depositDate)?.toGregorian();
        final bDate = NepaliDate.parse(b.depositDate)?.toGregorian();
        if (aDate == null || bDate == null) return 0;
        return aDate.compareTo(bDate);
      });

    for (final lot in ordered) {
      if (remaining <= 0) break;
      final taken = remaining > lot.remainingPrincipal
          ? lot.remainingPrincipal
          : remaining;
      if (taken > 0) {
        result.add(DepositWithdrawalAllocation(lot: lot, amount: taken));
        remaining -= taken;
      }
    }
    return result;
  }

  void withdrawPrincipal({
    required double amount,
    required String nepaliDateString,
    String? description,
  }) {
    if (amount > totalPrincipal + 0.0001) {
      throw ArgumentError('Withdrawal exceeds available principal');
    }
    final allocations = previewPrincipalWithdrawal(amount);
    final updatedLots = List<CashDepositLot>.from(lots);
    for (final allocation in allocations) {
      final index = updatedLots.indexWhere((lot) => lot.id == allocation.lot.id);
      if (index == -1) continue;
      final lot = updatedLots[index];
      lot.remainingPrincipal -= allocation.amount;
      if (lot.remainingPrincipal < 0.0001) lot.remainingPrincipal = 0;
      updatedLots[index] = lot;
    }
    lots = updatedLots;
    transactions = List<DepositTransaction>.from(transactions)
      ..add(
        DepositTransaction(
          type: 'Withdrawal',
          source: 'Principal Withdrawal',
          amount: amount,
          dateNepali: nepaliDateString,
          description: description ?? _allocationDescription(allocations),
          balanceAfter: totalAmountOwed,
          principalBalanceAfter: totalPrincipal,
          interestBalanceAfter: acquiredInterest,
          totalBalanceAfter: totalAmountOwed,
        ),
      );
  }

  void withdrawInterest({
    required double amount,
    required String nepaliDateString,
    String? description,
  }) {
    if (amount > acquiredInterest + 0.0001) {
      throw ArgumentError('Withdrawal exceeds available interest');
    }
    var remaining = amount;
    final updatedLots = List<CashDepositLot>.from(lots);
    for (var i = 0; i < updatedLots.length; i++) {
      if (remaining <= 0) break;
      final lot = updatedLots[i];
      if (lot.remainingInterest <= 0) continue;
      final taken = remaining > lot.remainingInterest
          ? lot.remainingInterest
          : remaining;
      lot.remainingInterest -= taken;
      if (lot.remainingInterest < 0.0001) lot.remainingInterest = 0;
      updatedLots[i] = lot;
      remaining -= taken;
    }
    lots = updatedLots;
    transactions = List<DepositTransaction>.from(transactions)
      ..add(
        DepositTransaction(
          type: 'Withdrawal',
          source: 'Interest Withdrawal',
          amount: amount,
          dateNepali: nepaliDateString,
          description: description,
          balanceAfter: totalAmountOwed,
          principalBalanceAfter: totalPrincipal,
          interestBalanceAfter: acquiredInterest,
          totalBalanceAfter: totalAmountOwed,
        ),
      );
  }

  void migrateLegacyTransactionsToLots() {
    if (lots.isNotEmpty || transactions.isEmpty) return;
    final ordered = List<DepositTransaction>.from(transactions)
      ..sort((a, b) {
        final adA = a.dateAD ?? NepaliDate.parse(a.dateNepali)?.toGregorian();
        final adB = b.dateAD ?? NepaliDate.parse(b.dateNepali)?.toGregorian();
        if (adA == null || adB == null) return 0;
        return adA.compareTo(adB);
      });

    transactions = [];
    lots = [];
    for (final txn in ordered) {
      if (txn.type == 'Deposit') {
        addDepositLot(
          amount: txn.amount,
          nepaliDateString: txn.dateNepali,
          rate: interestRate,
          description: txn.description ?? 'Migrated deposit',
        );
      } else if (txn.type == 'Withdrawal' && txn.amount <= totalPrincipal) {
        withdrawPrincipal(
          amount: txn.amount,
          nepaliDateString: txn.dateNepali,
          description: txn.description ?? 'Migrated withdrawal',
        );
      }
    }
  }

  List<DepositTransaction> get transactionsSortedDesc {
    final list = List<DepositTransaction>.from(transactions);
    list.sort((a, b) {
      final adA = a.dateAD ?? NepaliDate.parse(a.dateNepali)?.toGregorian();
      final adB = b.dateAD ?? NepaliDate.parse(b.dateNepali)?.toGregorian();
      if (adA == null && adB == null) return 0;
      if (adA == null) return 1;
      if (adB == null) return -1;
      return adB.compareTo(adA);
    });
    return list;
  }

  String _allocationDescription(List<DepositWithdrawalAllocation> allocations) {
    return allocations
        .map((a) => '${a.lot.depositDate}: NPR ${a.amount.toStringAsFixed(2)}')
        .join(', ');
  }
}

class DepositWithdrawalAllocation {
  final CashDepositLot lot;
  final double amount;

  const DepositWithdrawalAllocation({required this.lot, required this.amount});
}

class DepositTransactionAdapter extends TypeAdapter<DepositTransaction> {
  @override
  final int typeId = 3;

  @override
  DepositTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    final balanceAfter = (fields[4] as num).toDouble();
    return DepositTransaction(
      type: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      dateNepali: fields[2] as String,
      description: fields[3] as String?,
      balanceAfter: balanceAfter,
      dateAD: fields[5] as DateTime?,
      source: fields[6] as String?,
      lotId: fields[7] as String?,
      principalBalanceAfter: fields.containsKey(8)
          ? (fields[8] as num).toDouble()
          : balanceAfter,
      interestBalanceAfter: fields.containsKey(9)
          ? (fields[9] as num).toDouble()
          : 0,
      totalBalanceAfter: fields.containsKey(10)
          ? (fields[10] as num).toDouble()
          : balanceAfter,
    );
  }

  @override
  void write(BinaryWriter writer, DepositTransaction obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.dateNepali)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.balanceAfter)
      ..writeByte(5)
      ..write(obj.dateAD)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.lotId)
      ..writeByte(8)
      ..write(obj.principalBalanceAfter)
      ..writeByte(9)
      ..write(obj.interestBalanceAfter)
      ..writeByte(10)
      ..write(obj.totalBalanceAfter);
  }
}

class DepositModelAdapter extends TypeAdapter<DepositModel> {
  @override
  final int typeId = 2;

  @override
  DepositModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return DepositModel(
      depositId: fields[0] as String?,
      name: fields[1] as String,
      address: fields[2] as String,
      phone: fields[3] as String,
      interestRate: (fields[4] as num).toDouble(),
      description: fields[5] as String?,
      transactions: (fields[6] as List?)?.cast<DepositTransaction>() ?? [],
      lots: (fields[7] as List?)?.cast<CashDepositLot>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, DepositModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.depositId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.interestRate)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.transactions)
      ..writeByte(7)
      ..write(obj.lots);
  }
}

class CashDepositLotAdapter extends TypeAdapter<CashDepositLot> {
  @override
  final int typeId = 11;

  @override
  CashDepositLot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CashDepositLot(
      id: fields[0] as String?,
      customerId: fields[1] as String,
      originalAmount: (fields[2] as num).toDouble(),
      remainingPrincipal: (fields[3] as num).toDouble(),
      depositDate: fields[4] as String,
      maturityDate: fields[5] as String,
      interestRate: (fields[6] as num).toDouble(),
      acquiredInterest: fields.containsKey(7)
          ? (fields[7] as num).toDouble()
          : 0,
      remainingInterest: fields.containsKey(8)
          ? (fields[8] as num).toDouble()
          : 0,
      status: fields.containsKey(9) ? fields[9] as String : 'Not Matured',
      interestApplied: fields.containsKey(10) ? fields[10] as bool : false,
    );
  }

  @override
  void write(BinaryWriter writer, CashDepositLot obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.originalAmount)
      ..writeByte(3)
      ..write(obj.remainingPrincipal)
      ..writeByte(4)
      ..write(obj.depositDate)
      ..writeByte(5)
      ..write(obj.maturityDate)
      ..writeByte(6)
      ..write(obj.interestRate)
      ..writeByte(7)
      ..write(obj.acquiredInterest)
      ..writeByte(8)
      ..write(obj.remainingInterest)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.interestApplied);
  }
}
