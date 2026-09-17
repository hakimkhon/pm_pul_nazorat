// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionModelAdapter
    extends TypeAdapter<RecurringTransactionModel> {
  @override
  final int typeId = 3;

  @override
  RecurringTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      categoryId: fields[2] as String,
      type: fields[3] as String,
      frequency: fields[4] as String,
      startDate: fields[5] as DateTime,
      lastGeneratedDate: fields[6] as DateTime,
      note: fields[7] as String?,
      source: fields[8] as String?,
      isActive: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransactionModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.frequency)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.lastGeneratedDate)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.source)
      ..writeByte(9)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
