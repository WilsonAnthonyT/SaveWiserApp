// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      category: fields[0] as String,
      amount: fields[1] as double,
      month: fields[2] as int,
      year: fields[3] as int,
      date: fields[4] as int?,
      transactionType: fields[5] as String?,
      description: fields[6] as String?,
      currency: fields[7] as String?,
      cpfPortion: fields[8] as double,
      usablePortion: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.month)
      ..writeByte(3)
      ..write(obj.year)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.transactionType)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.currency)
      ..writeByte(8)
      ..write(obj.cpfPortion)
      ..writeByte(9)
      ..write(obj.usablePortion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
