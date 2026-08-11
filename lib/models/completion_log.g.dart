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
    );
  }

  @override
  void write(BinaryWriter writer, CompletionLog obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.completedAt);
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
