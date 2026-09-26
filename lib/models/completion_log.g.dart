// GENERATED CODE - Hand-written TypeAdapter (no build_runner dependency)
// ignore_for_file: constant_identifier_names

part of 'completion_log.dart';

class CompletionLogAdapter extends TypeAdapter<CompletionLog> {
  @override
  final int typeId = 1;

  @override
  CompletionLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompletionLog(
      id: fields[0] as String,
      taskId: fields[1] as String,
      taskName: fields[2] as String,
      iconIndex: fields[3] as int,
      memo: fields[4] as String,
      minutes: fields[5] as int,
      completedAt: fields[6] as DateTime,
      distanceMeters: fields[7] as double?,
      steps: fields[8] as int?,
      updatedAt: fields[9] == null
          ? (fields[6] as DateTime)
          : fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompletionLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.taskName)
      ..writeByte(3)
      ..write(obj.iconIndex)
      ..writeByte(4)
      ..write(obj.memo)
      ..writeByte(5)
      ..write(obj.minutes)
      ..writeByte(6)
      ..write(obj.completedAt)
      ..writeByte(7)
      ..write(obj.distanceMeters)
      ..writeByte(8)
      ..write(obj.steps)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
