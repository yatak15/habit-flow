import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/firebase_config.dart';
import '../models/completion_log.dart';
import '../models/task.dart';
import 'task_service.dart';

/// Firebase（Authentication + Cloud Firestore）を使ったアカウント認証と端末間同期。
/// 端末内の Hive を正としつつ、ドキュメント単位で「更新日時が新しい方が勝つ」ルールでマージする。
/// 接続情報が未設定の場合は何もせず、従来どおり端末内のみで動作する。
///
/// 保存先: users/{uid}/habits/{taskId}, users/{uid}/logs/{logId}
class SyncService extends ChangeNotifier {
  SyncService(this._tasks);

  final TaskService _tasks;

  bool _initialized = false;
  bool _syncing = false;
  DateTime? _lastSyncedAt;
  String? _lastError;
  Timer? _debounce;

  bool get isConfigured => FirebaseConfig.isConfigured;
  bool get isSyncing => _syncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  FirebaseAuth? get _auth => _initialized ? FirebaseAuth.instance : null;
  User? get user => _auth?.currentUser;
  bool get isSignedIn => user != null;
  String? get email => user?.email;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(user!.uid);

  Future<void> init() async {
    final options = FirebaseConfig.currentPlatform;
    if (options == null) return;
    await Firebase.initializeApp(options: options);
    // 端末内の Hive を正とするため、Firestore 側のオフラインキャッシュは使わない
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    _initialized = true;

    _auth!.authStateChanges().listen((u) {
      notifyListeners();
      if (u != null) sync();
    });
    _tasks.addListener(_onLocalChange);
  }

  void _onLocalChange() {
    if (!isSignedIn || _syncing) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), sync);
  }

  /// 成功時は null、失敗時は表示用のメッセージを返す
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      return '通信に失敗しました。ネットワークを確認してください。';
    }
  }

  /// 成功時は null（登録と同時にログインする）
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _authMessage(e);
    } catch (e) {
      return '通信に失敗しました。ネットワークを確認してください。';
    }
  }

  String _authMessage(FirebaseAuthException e) => switch (e.code) {
    'invalid-email' => 'メールアドレスの形式が正しくありません。',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'メールアドレスまたはパスワードが違います。',
    'email-already-in-use' => 'このメールアドレスはすでに登録されています。ログインしてください。',
    'weak-password' => 'パスワードは6文字以上にしてください。',
    'too-many-requests' => '試行回数が多すぎます。しばらくしてからお試しください。',
    'network-request-failed' => '通信に失敗しました。ネットワークを確認してください。',
    _ => e.message ?? 'ログインに失敗しました。',
  };

  Future<void> signOut() async {
    _debounce?.cancel();
    await _auth?.signOut();
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

  /// 1回のバッチ書き込みは500件までのため、分割して書き込む
  Future<void> _commitAll(
    CollectionReference<Map<String, dynamic>> col,
    List<Map<String, dynamic>> docs,
  ) async {
    for (var i = 0; i < docs.length; i += 500) {
      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs.skip(i).take(500)) {
        batch.set(col.doc(d['id'] as String), d);
      }
      await batch.commit();
    }
  }

  // ---- 削除の反映（削除印 deletedAt を付ける） ----

  Future<void> _pushDeletions() async {
    final pending = _tasks.pendingDeletes;
    if (pending.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final entry in pending.entries) {
      final sep = entry.key.indexOf(':');
      final collection = entry.key.substring(0, sep) == 'tasks'
          ? 'habits'
          : 'logs';
      final id = entry.key.substring(sep + 1);
      final at = Timestamp.fromDate(DateTime.parse(entry.value));
      batch.set(_userDoc.collection(collection).doc(id), {
        'id': id,
        'deletedAt': at,
        'updatedAt': at,
      }, SetOptions(merge: true));
    }
    await batch.commit();
    await _tasks.clearPendingDeletes(pending.keys);
  }

  // ---- タスク ----

  Future<void> _syncTasks() async {
    final col = _userDoc.collection('habits');
    final remote = await col.get();
    final local = {for (final t in _tasks.allTasks) t.id: t};
    final remoteIds = <String>{};
    final toPush = <Map<String, dynamic>>[];

    for (final doc in remote.docs) {
      final r = doc.data();
      final id = doc.id;
      remoteIds.add(id);
      final remoteUpdated = _dt(r['updatedAt'])!;
      final deletedAt = _dt(r['deletedAt']);
      final l = local[id];

      if (deletedAt != null) {
        if (l == null) continue;
        if (l.updatedAt.isAfter(deletedAt)) {
          toPush.add(_taskToDoc(l));
        } else {
          await _tasks.removeLocalTask(id);
        }
      } else if (l == null || remoteUpdated.isAfter(l.updatedAt)) {
        await _tasks.applyRemoteTask(_taskFromDoc(id, r));
      } else if (l.updatedAt.isAfter(remoteUpdated)) {
        toPush.add(_taskToDoc(l));
      }
    }
    for (final l in local.values) {
      if (!remoteIds.contains(l.id)) toPush.add(_taskToDoc(l));
    }
    await _commitAll(col, toPush);
  }

  Map<String, dynamic> _taskToDoc(Task t) => {
    'id': t.id,
    'name': t.name,
    'iconIndex': t.iconIndex,
    'defaultMinutes': t.defaultMinutes,
    'lastMemo': t.lastMemo,
    'totalCount': t.totalCount,
    'currentStreak': t.currentStreak,
    'bestStreak': t.bestStreak,
    'lastCompletedDate': _ts(t.lastCompletedDate),
    'createdAt': _ts(t.createdAt),
    'cumulativeMinutes': t.cumulativeMinutes,
    'modeIndex': t.modeIndex,
    'trackFitness': t.trackFitness,
    'cumulativeDistanceMeters': t.cumulativeDistanceMeters,
    'cumulativeSteps': t.cumulativeSteps,
    'updatedAt': _ts(t.updatedAt),
    'deletedAt': null,
  };

  Task _taskFromDoc(String id, Map<String, dynamic> r) => Task(
    id: id,
    name: r['name'] as String,
    iconIndex: r['iconIndex'] as int,
    defaultMinutes: r['defaultMinutes'] as int,
    lastMemo: r['lastMemo'] as String,
    totalCount: r['totalCount'] as int,
    currentStreak: r['currentStreak'] as int,
    bestStreak: r['bestStreak'] as int,
    lastCompletedDate: _dt(r['lastCompletedDate']),
    createdAt: _dt(r['createdAt'])!,
    cumulativeMinutes: r['cumulativeMinutes'] as int,
    modeIndex: r['modeIndex'] as int,
    trackFitness: r['trackFitness'] as bool,
    cumulativeDistanceMeters: (r['cumulativeDistanceMeters'] as num)
        .toDouble(),
    cumulativeSteps: r['cumulativeSteps'] as int,
    updatedAt: _dt(r['updatedAt'])!,
  );

  // ---- 完了ログ ----

  Future<void> _syncLogs() async {
    final col = _userDoc.collection('logs');
    final remote = await col.get();
    final local = {for (final l in _tasks.allLogs) l.id: l};
    final remoteIds = <String>{};
    final toPush = <Map<String, dynamic>>[];

    for (final doc in remote.docs) {
      final r = doc.data();
      final id = doc.id;
      remoteIds.add(id);
      final remoteUpdated = _dt(r['updatedAt'])!;
      final deletedAt = _dt(r['deletedAt']);
      final l = local[id];

      if (deletedAt != null) {
        if (l == null) continue;
        if (l.updatedAt.isAfter(deletedAt)) {
          toPush.add(_logToDoc(l));
        } else {
          await _tasks.removeLocalLog(id);
        }
      } else if (l == null || remoteUpdated.isAfter(l.updatedAt)) {
        await _tasks.applyRemoteLog(_logFromDoc(id, r));
      } else if (l.updatedAt.isAfter(remoteUpdated)) {
        toPush.add(_logToDoc(l));
      }
    }
    for (final l in local.values) {
      if (!remoteIds.contains(l.id)) toPush.add(_logToDoc(l));
    }
    await _commitAll(col, toPush);
  }

  Map<String, dynamic> _logToDoc(CompletionLog l) => {
    'id': l.id,
    'taskId': l.taskId,
    'taskName': l.taskName,
    'iconIndex': l.iconIndex,
    'memo': l.memo,
    'minutes': l.minutes,
    'completedAt': _ts(l.completedAt),
    'distanceMeters': l.distanceMeters,
    'steps': l.steps,
    'updatedAt': _ts(l.updatedAt),
    'deletedAt': null,
  };

  CompletionLog _logFromDoc(String id, Map<String, dynamic> r) => CompletionLog(
    id: id,
    taskId: r['taskId'] as String,
    taskName: r['taskName'] as String,
    iconIndex: r['iconIndex'] as int,
    memo: r['memo'] as String,
    minutes: r['minutes'] as int,
    completedAt: _dt(r['completedAt'])!,
    distanceMeters: (r['distanceMeters'] as num?)?.toDouble(),
    steps: r['steps'] as int?,
    updatedAt: _dt(r['updatedAt'])!,
  );

  Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);

  DateTime? _dt(dynamic v) => (v as Timestamp?)?.toDate();

  @override
  void dispose() {
    _debounce?.cancel();
    _tasks.removeListener(_onLocalChange);
    super.dispose();
  }
}
