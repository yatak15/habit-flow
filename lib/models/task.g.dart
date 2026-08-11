// GENERATED CODE - Hand-written TypeAdapter (no build_runner dependency)
// ignore_for_file: constant_identifier_names

part of 'task.dart';

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      name: fields[1] as String,
      iconIndex: fields[2] as int,
      defaultMinutes: fields[3] as int,
      lastMemo: fields[4] as String,
      totalCount: fields[5] as int,
      currentStreak: fields[6] as int,
      bestStreak: fields[7] as int,
      lastCompletedDate: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.iconIndex)
      ..writeByte(3)
      ..write(obj.defaultMinutes)
      ..writeByte(4)
      ..write(obj.lastMemo)
      ..writeByte(5)
      ..write(obj.totalCount)
      ..writeByte(6)
      ..write(obj.currentStreak)
      ..writeByte(7)
      ..write(obj.bestStreak)
      ..writeByte(8)
      ..write(obj.lastCompletedDate)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
