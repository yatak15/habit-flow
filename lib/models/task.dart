import 'package:hive/hive.dart';
import 'task_icon.dart';

part 'task.g.dart';

/// タスク（例：ピアノ10分レッスン、ギター10分練習）
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int iconIndex; // TaskIconType.index

  @HiveField(3)
  int defaultMinutes; // デフォルトのタイマー時間（分）

  @HiveField(4)
  String lastMemo; // 直近使用したメモ

  @HiveField(5)
  int totalCount; // 実行回数（タスク実行回数）

  @HiveField(6)
  int currentStreak; // 現在の継続日数

  @HiveField(7)
  int bestStreak; // 最長継続日数

  @HiveField(8)
  DateTime? lastCompletedDate; // 最後に完了した日付（時刻を除いた日付）

  @HiveField(9)
  DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    required this.iconIndex,
    this.defaultMinutes = 10,
    this.lastMemo = '',
    this.totalCount = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompletedDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TaskIconType get iconType => TaskIconType.values[iconIndex];
}
