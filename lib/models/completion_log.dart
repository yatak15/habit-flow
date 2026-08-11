import 'package:hive/hive.dart';

part 'completion_log.g.dart';

/// タスク完了の記録（タイマー終了時に1件追加）
@HiveType(typeId: 1)
class CompletionLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String taskName;

  @HiveField(3)
  int iconIndex;

  @HiveField(4)
  String memo;

  @HiveField(5)
  int minutes;

  @HiveField(6)
  DateTime completedAt;

  CompletionLog({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.iconIndex,
    required this.memo,
    required this.minutes,
    required this.completedAt,
  });
}
