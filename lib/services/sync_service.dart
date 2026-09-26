import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/completion_log.dart';
import '../models/task.dart';
import 'task_service.dart';

/// Supabase を使ったアカウント認証と端末間同期。
/// 端末内の Hive を正としつつ、行単位で「更新日時が新しい方が勝つ」ルールでマージする。
/// 接続情報が未設定の場合は何もせず、従来どおり端末内のみで動作する。
class SyncService extends ChangeNotifier {
  SyncService(this._tasks);

  final TaskService _tasks;

  bool _initialized = false;
  bool _syncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;
  Timer? _debounce;

  bool get isConfigured => SupabaseConfig.isConfigured;
  bool get isSyncing => _syncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  SupabaseClient? get _client => _initialized ? Supabase.instance.client : null;
  User? get user => _client?.auth.currentUser;
  bool get isSignedIn => user != null;
  String? get email => user?.email;

  Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    _initialized = true;

    _client!.auth.onAuthStateChange.listen((data) {
      notifyListeners();
      if (data.session != null) sync();
    });
    _tasks.addListener(_onLocalChange);

    if (isSignedIn) unawaited(sync());
  }

  void _onLocalChange() {
    if (!isSignedIn || _syncing) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), sync);
  }

  /// 成功時は null、失敗時は表示用のメッセージを返す
  Future<String?> signIn(String email, String password) async {
    try {
      await _client!.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '通信に失敗しました。ネットワークを確認してください。';
    }
  }

  /// 成功時は null。メール確認が必要な設定の場合はその旨のメッセージを返す
  Future<String?> signUp(String email, String password) async {
    try {
      final res = await _client!.auth.signUp(email: email, password: password);
      if (res.session == null) {
        return '確認メールを送信しました。メール内のリンクを開いたあと、ログインしてください。';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '通信に失敗しました。ネットワークを確認してください。';
    }
  }

  Future<void> signOut() async {
    _debounce?.cancel();
    await _client?.auth.signOut();
    _lastSyncedAt = null;
    _lastError = null;
    notifyListeners();
  }

  Future<void> sync() async {
    if (!isSignedIn || _syncing) return;
    _debounce?.cancel();
    _syncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _pushDeletions();
      await _syncTasks();
      await _syncLogs();
      _lastSyncedAt = DateTime.now();
      _tasks.notifySynced();
    } catch (e) {
      debugPrint('sync failed: $e');
      _lastError = '同期に失敗しました。時間をおいて再度お試しください。';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  // ---- 削除の反映（削除印 deleted_at を付ける） ----

  Future<void> _pushDeletions() async {
    final pending = _tasks.pendingDeletes;
    if (pending.isEmpty) return;
    final c = _client!;
    for (final entry in pending.entries) {
      final sep = entry.key.indexOf(':');
      final table = entry.key.substring(0, sep) == 'tasks'
          ? 'tasks'
          : 'completion_logs';
      final id = entry.key.substring(sep + 1);
      await c
          .from(table)
          .update({'deleted_at': entry.value, 'updated_at': entry.value})
          .eq('id', id);
    }
    await _tasks.clearPendingDeletes(pending.keys);
  }

  // ---- タスク ----

  Future<void> _syncTasks() async {
    final c = _client!;
    final remote = await c.from('tasks').select();
    final local = {for (final t in _tasks.allTasks) t.id: t};
    final remoteIds = <String>{};
    final toPush = <Map<String, dynamic>>[];

    for (final r in remote) {
      final id = r['id'] as String;
      remoteIds.add(id);
      final remoteUpdated = _dt(r['updated_at'])!;
      final deletedAt = _dt(r['deleted_at']);
      final l = local[id];

      if (deletedAt != null) {
        if (l == null) continue;
        if (l.updatedAt.isAfter(deletedAt)) {
          toPush.add(_taskToRow(l));
        } else {
          await _tasks.removeLocalTask(id);
        }
      } else if (l == null || remoteUpdated.isAfter(l.updatedAt)) {
        await _tasks.applyRemoteTask(_taskFromRow(r));
      } else if (l.updatedAt.isAfter(remoteUpdated)) {
        toPush.add(_taskToRow(l));
      }
    }
    for (final l in local.values) {
      if (!remoteIds.contains(l.id)) toPush.add(_taskToRow(l));
    }
    if (toPush.isNotEmpty) {
      await c.from('tasks').upsert(toPush, onConflict: 'user_id,id');
    }
  }

  Map<String, dynamic> _taskToRow(Task t) => {
    'id': t.id,
    'name': t.name,
    'icon_index': t.iconIndex,
    'default_minutes': t.defaultMinutes,
    'last_memo': t.lastMemo,
    'total_count': t.totalCount,
    'current_streak': t.currentStreak,
    'best_streak': t.bestStreak,
    'last_completed_date': t.lastCompletedDate?.toUtc().toIso8601String(),
    'created_at': t.createdAt.toUtc().toIso8601String(),
    'cumulative_minutes': t.cumulativeMinutes,
    'mode_index': t.modeIndex,
    'track_fitness': t.trackFitness,
    'cumulative_distance_meters': t.cumulativeDistanceMeters,
    'cumulative_steps': t.cumulativeSteps,
    'updated_at': t.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };

  Task _taskFromRow(Map<String, dynamic> r) => Task(
    id: r['id'] as String,
    name: r['name'] as String,
    iconIndex: r['icon_index'] as int,
    defaultMinutes: r['default_minutes'] as int,
    lastMemo: r['last_memo'] as String,
    totalCount: r['total_count'] as int,
    currentStreak: r['current_streak'] as int,
    bestStreak: r['best_streak'] as int,
    lastCompletedDate: _dt(r['last_completed_date']),
    createdAt: _dt(r['created_at'])!,
    cumulativeMinutes: r['cumulative_minutes'] as int,
    modeIndex: r['mode_index'] as int,
    trackFitness: r['track_fitness'] as bool,
    cumulativeDistanceMeters: (r['cumulative_distance_meters'] as num)
        .toDouble(),
    cumulativeSteps: r['cumulative_steps'] as int,
    updatedAt: _dt(r['updated_at'])!,
  );

  // ---- 完了ログ ----

  Future<void> _syncLogs() async {
    final c = _client!;
    final remote = await c.from('completion_logs').select();
    final local = {for (final l in _tasks.allLogs) l.id: l};
    final remoteIds = <String>{};
    final toPush = <Map<String, dynamic>>[];

    for (final r in remote) {
      final id = r['id'] as String;
      remoteIds.add(id);
      final remoteUpdated = _dt(r['updated_at'])!;
      final deletedAt = _dt(r['deleted_at']);
      final l = local[id];

      if (deletedAt != null) {
        if (l == null) continue;
        if (l.updatedAt.isAfter(deletedAt)) {
          toPush.add(_logToRow(l));
        } else {
          await _tasks.removeLocalLog(id);
        }
      } else if (l == null || remoteUpdated.isAfter(l.updatedAt)) {
        await _tasks.applyRemoteLog(_logFromRow(r));
      } else if (l.updatedAt.isAfter(remoteUpdated)) {
        toPush.add(_logToRow(l));
      }
    }
    for (final l in local.values) {
      if (!remoteIds.contains(l.id)) toPush.add(_logToRow(l));
    }
    if (toPush.isNotEmpty) {
      await c.from('completion_logs').upsert(toPush, onConflict: 'user_id,id');
    }
  }

  Map<String, dynamic> _logToRow(CompletionLog l) => {
    'id': l.id,
    'task_id': l.taskId,
    'task_name': l.taskName,
    'icon_index': l.iconIndex,
    'memo': l.memo,
    'minutes': l.minutes,
    'completed_at': l.completedAt.toUtc().toIso8601String(),
    'distance_meters': l.distanceMeters,
    'steps': l.steps,
    'updated_at': l.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };

  CompletionLog _logFromRow(Map<String, dynamic> r) => CompletionLog(
    id: r['id'] as String,
    taskId: r['task_id'] as String,
    taskName: r['task_name'] as String,
    iconIndex: r['icon_index'] as int,
    memo: r['memo'] as String,
    minutes: r['minutes'] as int,
    completedAt: _dt(r['completed_at'])!,
    distanceMeters: (r['distance_meters'] as num?)?.toDouble(),
    steps: r['steps'] as int?,
    updatedAt: _dt(r['updated_at'])!,
  );

  DateTime? _dt(dynamic v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  @override
  void dispose() {
    _debounce?.cancel();
    _tasks.removeListener(_onLocalChange);
    super.dispose();
  }
}
