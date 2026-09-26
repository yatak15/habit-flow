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

  @HiveField(7)
  double? distanceMeters; // 走行距離（ランニングなど、記録した場合のみ）

  @HiveField(8)
  int? steps; // 歩数（ランニングなど、記録した場合のみ）

  @HiveField(9)
  DateTime updatedAt; // 最終更新日時（端末間同期の新旧判定に使用）

  CompletionLog({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.iconIndex,
    required this.memo,
    required this.minutes,
    required this.completedAt,
    this.distanceMeters,
    this.steps,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  @override
  Future<void> save() {
    updatedAt = DateTime.now();
    return super.save();
  }
}
