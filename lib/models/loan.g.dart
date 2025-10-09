// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoanAdapter extends TypeAdapter<Loan> {
  @override
  final int typeId = 0;

  @override
  Loan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Loan(
      name: fields[0] as String,
      date: fields[1] as DateTime,
      duration: fields[2] as int,
      interestRate: fields[3] as double,
      type: fields[4] as String,
      jewelleryName: fields[5] as String,
      serialNumber: fields[6] as String,
      phone: fields[7] as String,
      address: fields[8] as String,
      description: fields[9] as String,
      amountGiven: fields[10] as double,
      amountReceived: fields[11] as double,
      partialRepayments: (fields[12] as List?)?.cast<PartialRepayment>(),
      nepaliDateString: fields[13] as String?,
      loanId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Loan obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(14)
      ..write(obj.loanId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(13)
      ..write(obj.nepaliDateString)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.interestRate)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.jewelleryName)
      ..writeByte(6)
      ..write(obj.serialNumber)
      ..writeByte(7)
      ..write(obj.phone)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(9)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.amountGiven)
      ..writeByte(11)
      ..write(obj.amountReceived)
      ..writeByte(12)
      ..write(obj.partialRepayments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PartialRepaymentAdapter extends TypeAdapter<PartialRepayment> {
  @override
  final int typeId = 1;

  @override
  PartialRepayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartialRepayment(
      amount: fields[0] as double,
      date: fields[1] as DateTime,
      daysSinceLoan: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PartialRepayment obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.amount)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.daysSinceLoan);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartialRepaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
