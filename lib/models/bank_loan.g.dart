// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_loan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BankLoanAdapter extends TypeAdapter<BankLoan> {
  @override
  final int typeId = 10;

  @override
  BankLoan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankLoan(
      loanId: fields[0] as String,
      originalLoan: fields[2] as Loan,
      depositDate: fields[1] as DateTime,
      status: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BankLoan obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.loanId)
      ..writeByte(1)
      ..write(obj.depositDate)
      ..writeByte(2)
      ..write(obj.originalLoan)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankLoanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
