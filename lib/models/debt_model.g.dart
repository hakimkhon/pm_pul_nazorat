// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DebtPaymentModelAdapter extends TypeAdapter<DebtPaymentModel> {
  @override
  final int typeId = 5;

  @override
  DebtPaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtPaymentModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      note: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DebtPaymentModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtPaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DebtModelAdapter extends TypeAdapter<DebtModel> {
  @override
  final int typeId = 4;

  @override
  DebtModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DebtModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      type: fields[2] as String,
      totalAmount: fields[3] as double,
      date: fields[4] as DateTime,
      dueDate: fields[5] as DateTime?,
      note: fields[6] as String?,
      payments: (fields[7] as List?)?.cast<DebtPaymentModel>(),
      remindedOverdue: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DebtModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.payments)
      ..writeByte(8)
      ..write(obj.remindedOverdue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
