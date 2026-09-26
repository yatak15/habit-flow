import 'package:hive/hive.dart';
import 'task_icon.dart';

part 'task.g.dart';

/// タスクの種類
/// timed: 時間を計って「実行」する習慣（ピアノ練習など）
/// abstain: 「やらなかった日」を記録する習慣（禁酒など、タイマー不要）
enum TaskMode { timed, abstain }

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

  @HiveField(10)
  int cumulativeMinutes; // 累積実行時間（分）

  @HiveField(11)
  int modeIndex; // TaskMode.index（0: timed, 1: abstain）

  @HiveField(12)
  bool trackFitness; // ランニングなど：実行中に距離・歩数を記録するか

  @HiveField(13)
  double cumulativeDistanceMeters; // 累積走行距離（メートル）

  @HiveField(14)
  int cumulativeSteps; // 累積歩数

  @HiveField(15)
  DateTime updatedAt; // 最終更新日時（端末間同期の新旧判定に使用）

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
    this.cumulativeMinutes = 0,
    this.modeIndex = 0,
    this.trackFitness = false,
    this.cumulativeDistanceMeters = 0,
    this.cumulativeSteps = 0,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  @override
  Future<void> save() {
    updatedAt = DateTime.now();
    return super.save();
  }

  TaskMode get mode => TaskMode.values[modeIndex];
  bool get isAbstain => mode == TaskMode.abstain;

  /// タスク単体の実績をリセットする（累積時間・実行回数・継続日数・最長記録を初期化）
  void resetStats() {
    totalCount = 0;
    currentStreak = 0;
    bestStreak = 0;
    cumulativeMinutes = 0;
    cumulativeDistanceMeters = 0;
    cumulativeSteps = 0;
    lastCompletedDate = null;
  }

  TaskIconType get iconType => TaskIconType.values[iconIndex];
}
