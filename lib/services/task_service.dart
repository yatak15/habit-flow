import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/completion_log.dart';

/// タスクの永続化管理・継続日数(ストリーク)・実行回数の計算ロジックを担うサービス
class TaskService extends ChangeNotifier {
  static const String taskBoxName = 'tasks_box';
  static const String logBoxName = 'logs_box';

  static const String pendingDeleteBoxName = 'pending_deletes_box';

  late Box<Task> _taskBox;
  late Box<CompletionLog> _logBox;
  // 端末間同期用：ローカルで削除したレコード（キーは "tasks:ID" / "logs:ID"、値は削除日時）
  late Box<String> _pendingDeleteBox;

  List<Task> get tasks =>
      _taskBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<CompletionLog> get logs =>
      _logBox.values.toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>(taskBoxName);
    _logBox = await Hive.openBox<CompletionLog>(logBoxName);
    _pendingDeleteBox = await Hive.openBox<String>(pendingDeleteBoxName);

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
    TaskMode mode = TaskMode.timed,
    bool trackFitness = false,
  }) async {
    final task = Task(
      id: _generateId(),
      name: name,
      iconIndex: iconIndex,
      defaultMinutes: defaultMinutes,
      modeIndex: mode.index,
      trackFitness: trackFitness,
    );
    await _taskBox.put(task.id, task);
    notifyListeners();
    return task;
  }

  /// 既存タスクの名前・アイコン・デフォルトタイマー時間を編集する
  /// （タスクの種類＝続ける／やめたい、は履歴との整合性を保つため編集不可）
  Future<Task?> editTask(
    String taskId, {
    required String name,
    required int iconIndex,
    required int defaultMinutes,
    bool? trackFitness,
  }) async {
    final task = getTask(taskId);
    if (task == null) return null;
    task.name = name;
    task.iconIndex = iconIndex;
    task.defaultMinutes = defaultMinutes;
    if (trackFitness != null) task.trackFitness = trackFitness;
    await task.save();
    notifyListeners();
    return task;
  }

  Future<void> updateTask(Task task) async {
    await task.save();
    notifyListeners();
  }

  /// タスクを完全に削除する（関連する完了ログもすべて削除し、元に戻せない）
  Future<void> deleteTask(String taskId) async {
    for (final log in logsForTask(taskId)) {
      await _deleteLog(log);
    }
    _recordDelete('tasks', taskId);
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
    double? distanceMeters,
    int? steps,
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
    task.cumulativeMinutes += minutes;
    if (distanceMeters != null) {
      task.cumulativeDistanceMeters += distanceMeters;
    }
    if (steps != null) task.cumulativeSteps += steps;
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
      distanceMeters: distanceMeters,
      steps: steps,
    );
    await _logBox.put(log.id, log);

    notifyListeners();
  }

  /// タスクごとの完了回数一覧（履歴ページ用）
  List<CompletionLog> logsForTask(String taskId) {
    return logs.where((l) => l.taskId == taskId).toList();
  }

  /// 個別タスクの実績（累積時間・実行回数・継続日数・最長記録）をリセットする
  /// ※timedタスクは完了ログ（履歴）自体を削除しない。
  /// abstainタスクはログ＝チェック記録そのものであり、残すと次回チェック時に
  /// 統計が再計算されリセットが無意味になるため、ログも合わせて削除する。
  Future<void> resetTask(String taskId) async {
    final task = getTask(taskId);
    if (task == null) return;
    task.resetStats();
    await task.save();
    if (task.isAbstain) {
      for (final log in logsForTask(taskId)) {
        await _deleteLog(log);
      }
    }
    notifyListeners();
  }

  /// 指定日（お酒を飲まなかった日等）のチェック状態を判定する（abstainタスク用）
  bool isAbstainDayMarked(String taskId, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return logsForTask(taskId).any((l) {
      final d = DateTime(
        l.completedAt.year,
        l.completedAt.month,
        l.completedAt.day,
      );
      return d == target;
    });
  }

  /// 指定日のチェックをON/OFF切り替える（abstainタスク用）
  /// 記録忘れに備え、当日に限らず過去日も対象にできる。
  Future<void> toggleAbstainDay(String taskId, DateTime day) async {
    final task = getTask(taskId);
    if (task == null) return;
    final target = DateTime(day.year, day.month, day.day);

    final existing = logsForTask(taskId).where((l) {
      final d = DateTime(
        l.completedAt.year,
        l.completedAt.month,
        l.completedAt.day,
      );
      return d == target;
    }).toList();

    if (existing.isNotEmpty) {
      for (final log in existing) {
        await _deleteLog(log);
      }
    } else {
      final log = CompletionLog(
        id: _generateId(),
        taskId: task.id,
        taskName: task.name,
        iconIndex: task.iconIndex,
        memo: '',
        minutes: 0,
        completedAt: DateTime(target.year, target.month, target.day, 12),
      );
      await _logBox.put(log.id, log);
    }

    _recalculateAbstainStats(task);
    await task.save();
    notifyListeners();
  }

  /// abstainタスクの継続日数・最長記録・実行回数を、チェック済みの日付一覧から再計算する
  void _recalculateAbstainStats(Task task) {
    final days =
        logsForTask(task.id)
            .map(
              (l) => DateTime(
                l.completedAt.year,
                l.completedAt.month,
                l.completedAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    task.totalCount = days.length;
    task.lastCompletedDate = days.isEmpty ? null : days.last;

    int best = 0;
    int running = 0;
    DateTime? prev;
    for (final d in days) {
      if (prev != null && d.difference(prev).inDays == 1) {
        running += 1;
      } else {
        running = 1;
      }
      if (running > best) best = running;
      prev = d;
    }

    final daySet = days.toSet();
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    // 今日分が未チェックでも、昨日まで連続していれば継続中とみなす
    // （「前日のことなので記録し忘れても良い」という運用に合わせたグレース期間）
    if (!daySet.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    int current = 0;
    while (daySet.contains(cursor)) {
      current += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    task.currentStreak = current;
    task.bestStreak = current > best ? current : best;
  }

  /// 指定日に実行記録（タイマー実行 or あとから記録）があるか判定する（timedタスク用）
  bool isDayCompleted(String taskId, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return logsForTask(taskId).any((l) {
      final d = DateTime(
        l.completedAt.year,
        l.completedAt.month,
        l.completedAt.day,
      );
      return d == target;
    });
  }

  /// 指定日にタイマーを実際に使った実行記録があるか（分数>0の記録があるか）判定する
  /// 「あとから記録」チェックボックスがこの記録を誤って削除しないためのガードに使う
  bool hasTimedCompletion(String taskId, DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return logsForTask(taskId).any((l) {
      final d = DateTime(
        l.completedAt.year,
        l.completedAt.month,
        l.completedAt.day,
      );
      return d == target && l.minutes > 0;
    });
  }

  /// アプリを開けなかった日の記録忘れに備え、タイマーを使わず「実行した」ことだけを
  /// 記録する（timedタスク用）。実際にタイマーを使った記録（分数>0）がある日は
  /// 対象外（呼び出し側でUIを無効化する想定）。
  Future<void> toggleBackfillDay(String taskId, DateTime day) async {
    final task = getTask(taskId);
    if (task == null) return;
    final target = DateTime(day.year, day.month, day.day);

    final existingBackfill = logsForTask(taskId).where((l) {
      final d = DateTime(
        l.completedAt.year,
        l.completedAt.month,
        l.completedAt.day,
      );
      return d == target && l.minutes == 0;
    }).toList();

    if (existingBackfill.isNotEmpty) {
      for (final log in existingBackfill) {
        await _deleteLog(log);
      }
      task.totalCount -= existingBackfill.length;
      if (task.totalCount < 0) task.totalCount = 0;

      final lastDay = task.lastCompletedDate == null
          ? null
          : DateTime(
              task.lastCompletedDate!.year,
              task.lastCompletedDate!.month,
              task.lastCompletedDate!.day,
            );
      if (lastDay == target) {
        // 直近の継続日を取り消す場合のみ、継続日数を1日分ロールバックする
        final prevDay = target.subtract(const Duration(days: 1));
        final hasPrev = isDayCompleted(taskId, prevDay);
        task.currentStreak = hasPrev
            ? (task.currentStreak > 0 ? task.currentStreak - 1 : 0)
            : 0;
        task.lastCompletedDate = hasPrev ? prevDay : null;
      }
    } else {
      final log = CompletionLog(
        id: _generateId(),
        taskId: task.id,
        taskName: task.name,
        iconIndex: task.iconIndex,
        memo: '',
        minutes: 0,
        completedAt: DateTime(target.year, target.month, target.day, 12),
      );
      await _logBox.put(log.id, log);
      task.totalCount += 1;

      final lastDay = task.lastCompletedDate == null
          ? null
          : DateTime(
              task.lastCompletedDate!.year,
              task.lastCompletedDate!.month,
              task.lastCompletedDate!.day,
            );

      if (lastDay == null) {
        task.currentStreak = 1;
        task.lastCompletedDate = target;
      } else {
        final diff = target.difference(lastDay).inDays;
        if (diff == 1) {
          task.currentStreak += 1;
          task.lastCompletedDate = target;
        } else if (diff > 1) {
          task.currentStreak = 1;
          task.lastCompletedDate = target;
        }
        // diff <= 0：すでにより新しい日が記録済みの状態で過去の穴を埋める場合は、
        // 実行回数・履歴のみ反映し継続日数は変更しない（誤って継続日数を
        // 壊さないための安全側の挙動）
      }
      if (task.currentStreak > task.bestStreak) {
        task.bestStreak = task.currentStreak;
      }
    }

    await task.save();
    notifyListeners();
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

  /// 指定期間内での累積実行時間（分）
  int cumulativeMinutesSince(String taskId, DateTime since) {
    return logsForTaskSince(
      taskId,
      since,
    ).fold(0, (sum, l) => sum + l.minutes);
  }

  DateTime get startOfWeek => _startOfWeek;
  DateTime get startOfMonth => _startOfMonth;

  Future<void> _deleteLog(CompletionLog log) async {
    _recordDelete('logs', log.id);
    await log.delete();
  }

  void _recordDelete(String table, String id) {
    _pendingDeleteBox.put('$table:$id', DateTime.now().toUtc().toIso8601String());
  }

  // ---- 端末間同期（SyncService）用 ----

  List<Task> get allTasks => _taskBox.values.toList();
  List<CompletionLog> get allLogs => _logBox.values.toList();
  Map<String, String> get pendingDeletes =>
      Map<String, String>.from(_pendingDeleteBox.toMap().map((k, v) => MapEntry(k.toString(), v)));

  Future<void> clearPendingDeletes(Iterable<String> keys) =>
      _pendingDeleteBox.deleteAll(keys);

  /// 他端末の変更を反映する。updatedAt は書き換えず、削除履歴も残さない。
  Future<void> applyRemoteTask(Task task) => _taskBox.put(task.id, task);
  Future<void> applyRemoteLog(CompletionLog log) => _logBox.put(log.id, log);
  Future<void> removeLocalTask(String id) => _taskBox.delete(id);
  Future<void> removeLocalLog(String id) => _logBox.delete(id);

  void notifySynced() => notifyListeners();

  String _generateId() {
    final rand = Random();
    return '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(99999)}';
  }
}
