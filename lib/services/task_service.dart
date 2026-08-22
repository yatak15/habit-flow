import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/completion_log.dart';

/// タスクの永続化管理・継続日数(ストリーク)・実行回数の計算ロジックを担うサービス
class TaskService extends ChangeNotifier {
  static const String taskBoxName = 'tasks_box';
  static const String logBoxName = 'logs_box';

  late Box<Task> _taskBox;
  late Box<CompletionLog> _logBox;

  List<Task> get tasks =>
      _taskBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<CompletionLog> get logs =>
      _logBox.values.toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>(taskBoxName);
    _logBox = await Hive.openBox<CompletionLog>(logBoxName);

    // 初回起動時はサンプルタスクを用意
    if (_taskBox.isEmpty) {
      await addTask(name: 'ピアノ 10分レッスン', iconIndex: 0, defaultMinutes: 10);
      await addTask(name: 'ギター 10分練習', iconIndex: 1, defaultMinutes: 10);
    }
  }

  Future<Task> addTask({
    required String name,
    required int iconIndex,
    int defaultMinutes = 10,
  }) async {
    final task = Task(
      id: _generateId(),
      name: name,
      iconIndex: iconIndex,
      defaultMinutes: defaultMinutes,
    );
    await _taskBox.put(task.id, task);
    notifyListeners();
    return task;
  }

  Future<void> updateTask(Task task) async {
    await task.save();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
    notifyListeners();
  }

  Task? getTask(String id) {
    try {
      return _taskBox.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// タイマー終了時：完了記録の追加 + 実行回数/継続日数の更新
  Future<void> completeTask(
    Task task, {
    required String memo,
    required int minutes,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ストリーク（継続日数）判定
    if (task.lastCompletedDate != null) {
      final lastDay = DateTime(
        task.lastCompletedDate!.year,
        task.lastCompletedDate!.month,
        task.lastCompletedDate!.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        // 同日複数回実行 -> ストリークは変化なし
      } else if (diff == 1) {
        task.currentStreak += 1;
      } else {
        task.currentStreak = 1; // 継続が途切れたのでリセット
      }
    } else {
      task.currentStreak = 1;
    }

    if (task.currentStreak > task.bestStreak) {
      task.bestStreak = task.currentStreak;
    }

    task.totalCount += 1;
    task.lastCompletedDate = today;
    task.lastMemo = memo;
    await task.save();

    final log = CompletionLog(
      id: _generateId(),
      taskId: task.id,
      taskName: task.name,
      iconIndex: task.iconIndex,
      memo: memo,
      minutes: minutes,
      completedAt: now,
    );
    await _logBox.put(log.id, log);

    notifyListeners();
  }

  /// タスクごとの完了回数一覧（履歴ページ用）
  List<CompletionLog> logsForTask(String taskId) {
    return logs.where((l) => l.taskId == taskId).toList();
  }

  DateTime get _startOfWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1)); // 月曜始まり
  }

  DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// 今週（月曜〜）の全タスク合計実行回数（Momentum Strip用）
  int get weeklyExecutionCount =>
      logs.where((l) => !l.completedAt.isBefore(_startOfWeek)).length;

  /// 全タスクの中での最長継続日数（Momentum Strip用）
  int get overallLongestStreak {
    if (tasks.isEmpty) return 0;
    return tasks.map((t) => t.bestStreak).reduce((a, b) => a > b ? a : b);
  }

  /// 現在継続日数が最も高いタスク（次のプライズ表示の基準に使用）
  Task? get topStreakTask {
    if (tasks.isEmpty) return null;
    final sorted = [...tasks]
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    return sorted.first;
  }

  /// 指定期間（週/月）内のログのみに絞り込む
  List<CompletionLog> logsForTaskSince(String taskId, DateTime since) {
    return logsForTask(
      taskId,
    ).where((l) => !l.completedAt.isBefore(since)).toList();
  }

  DateTime get startOfWeek => _startOfWeek;
  DateTime get startOfMonth => _startOfMonth;

  String _generateId() {
    final rand = Random();
    return '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(99999)}';
  }
}
