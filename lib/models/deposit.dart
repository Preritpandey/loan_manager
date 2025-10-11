import 'package:hive/hive.dart';
import 'package:list/utils/nepali_date_utils.dart';

// Note: No code generation. Manual Hive adapters are provided below.

// Use unique typeIds that do not conflict with existing ones:
// Loan = 0, PartialRepayment = 1 => Reserve 2,3 for deposits

@HiveType(typeId: 3)
class DepositTransaction extends HiveObject {
  // "Deposit" or "Withdrawal" for display
  @HiveField(0)
  String type;

  @HiveField(1)
  double amount;

  // Nepali date string (e.g., "2081 Baisakh 1") for display
  @HiveField(2)
  String dateNepali;

  // Optional description per txn
  @HiveField(3)
  String? description;

  // Balance after this transaction
  @HiveField(4)
  double balanceAfter;

  // Internal: cached AD date to help sorting (optional)
  @HiveField(5)
  DateTime? dateAD;

  DepositTransaction({
    required this.type,
    required this.amount,
    required this.dateNepali,
    this.description,
    required this.balanceAfter,
    DateTime? dateAD,
  }) : dateAD = dateAD ?? NepaliDate.parse(dateNepali)?.toGregorian();
}

@HiveType(typeId: 2)
class DepositModel extends HiveObject {
  // Unique identifier for this deposit account
  @HiveField(0)
  String depositId;

  @HiveField(1)
  String name;

  @HiveField(2)
  String address;

  @HiveField(3)
  String phone;

  // Yearly interest rate (display only, no auto calculation)
  @HiveField(4)
  double interestRate;

  // Optional description for the account
  @HiveField(5)
  String? description;

  // Transaction ledger
  @HiveField(6)
  List<DepositTransaction> transactions;

  DepositModel({
    String? depositId,
    required this.name,
    required this.address,
    required this.phone,
    required this.interestRate,
    this.description,
    List<DepositTransaction>? transactions,
  })  : depositId = depositId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        transactions = transactions ?? [];

  double get currentBalance {
    if (transactions.isEmpty) return 0.0;
    return transactions.last.balanceAfter;
    }

  String get latestTransactionDateNepali {
    if (transactions.isEmpty) return '-';
    return transactions.last.dateNepali;
  }

  void addTransaction({
    required String type, // 'Deposit' or 'Withdrawal'
    required double amount,
    required String nepaliDateString,
    String? description,
  }) {
    final prior = currentBalance;
    double next;
    if (type == 'Deposit') {
      next = prior + amount;
    } else if (type == 'Withdrawal') {
      next = prior - amount;
      if (next < 0) {
        // Prevent negative balances; clamp to zero
        next = 0;
      }
    } else {
      throw ArgumentError('Invalid transaction type: $type');
    }

    final txn = DepositTransaction(
      type: type,
      amount: amount,
      dateNepali: nepaliDateString,
      description: description,
      balanceAfter: next,
      dateAD: NepaliDate.parse(nepaliDateString)?.toGregorian(),
    );

    transactions = List<DepositTransaction>.from(transactions)..add(txn);
  }

  // Sort transactions newest first by AD date fallback to insertion order
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
}

// =========================
// Manual Hive Adapters
// =========================

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
    return DepositTransaction(
      type: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      dateNepali: fields[2] as String,
      description: fields[3] as String?,
      balanceAfter: (fields[4] as num).toDouble(),
      dateAD: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DepositTransaction obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.dateAD);
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
      transactions: (fields[6] as List).cast<DepositTransaction>(),
    );
  }

  @override
  void write(BinaryWriter writer, DepositModel obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.transactions);
  }
}