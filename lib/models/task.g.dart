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
      cumulativeMinutes: fields[10] == null ? 0 : fields[10] as int,
      modeIndex: fields[11] == null ? 0 : fields[11] as int,
      trackFitness: fields[12] == null ? false : fields[12] as bool,
      cumulativeDistanceMeters: fields[13] == null
          ? 0
          : fields[13] as double,
      cumulativeSteps: fields[14] == null ? 0 : fields[14] as int,
      updatedAt: fields[15] == null
          ? (fields[9] as DateTime)
          : fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.cumulativeMinutes)
      ..writeByte(11)
      ..write(obj.modeIndex)
      ..writeByte(12)
      ..write(obj.trackFitness)
      ..writeByte(13)
      ..write(obj.cumulativeDistanceMeters)
      ..writeByte(14)
      ..write(obj.cumulativeSteps)
      ..writeByte(15)
      ..write(obj.updatedAt);
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
