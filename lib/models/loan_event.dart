import 'package:hive/hive.dart';

@HiveType(typeId: 4)
class LoanPerformedEvent extends HiveObject {
  @HiveField(6)
  String name; // customer/deposit holder name
  @HiveField(0)
  String serialNumber;

  @HiveField(1)
  String type; // 'disbursement' | 'repayment' | 'topup'

  @HiveField(2)
  double amount; // positive for repayment/disbursement, positive magnitude for topup

  @HiveField(3)
  DateTime recordedDate; // the effective/statement date stored on the loan/repayment

  @HiveField(4)
  DateTime performedAt; // when the action was actually performed by loan giver

  @HiveField(5)
  String? description; // optional note

  @HiveField(7)
  String jewelleryName; // for loans; '-' for deposits

  @HiveField(8)
  double? dueAfter; // due amount after this transaction (for loans)

  LoanPerformedEvent({
    required this.name,
    required this.serialNumber,
    required this.type,
    required this.amount,
    required this.recordedDate,
    DateTime? performedAt,
    this.description,
    this.jewelleryName = '-',
    this.dueAfter,
  }) : performedAt = performedAt ?? DateTime.now();
}

class LoanPerformedEventAdapter extends TypeAdapter<LoanPerformedEvent> {
  @override
  final int typeId = 4;

  @override
  LoanPerformedEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return LoanPerformedEvent(
      name: (fields.containsKey(6) ? fields[6] : '') as String,
      serialNumber: fields[0] as String,
      type: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      recordedDate: fields[3] as DateTime,
      performedAt: fields[4] as DateTime,
      description: fields[5] as String?,
      jewelleryName: (fields.containsKey(7) ? fields[7] : '-') as String,
      dueAfter: fields.containsKey(8) ? (fields[8] as num?)?.toDouble() : null,
    );
  }

  @override
  void write(BinaryWriter writer, LoanPerformedEvent obj) {
    writer
      ..writeByte(9)
      ..writeByte(6)
      ..write(obj.name)
      ..writeByte(0)
      ..write(obj.serialNumber)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.recordedDate)
      ..writeByte(4)
      ..write(obj.performedAt)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.jewelleryName)
      ..writeByte(8)
      ..write(obj.dueAfter);
  }
}
