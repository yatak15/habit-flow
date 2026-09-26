import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 実行中タイマー／ストップウォッチの状態を永続化する。
/// アプリがバックグラウンドで完全終了（プロセスキル）された場合でも、
/// 次回起動時に画面へ復帰できるようにするための保存領域。
/// 同時に1つしか動かせないUI設計のため、単一レコードのみ保持する。
/// [referenceTime]は、カウントダウンタイマーでは「終了予定時刻」、
/// ストップウォッチでは「開始時刻」を表す。
class ActiveTimerRecord {
  final String taskId;
  final String memo;
  final int minutes;
  final DateTime referenceTime;
  final bool isStopwatch;

  ActiveTimerRecord({
    required this.taskId,
    required this.memo,
    required this.minutes,
    required this.referenceTime,
    this.isStopwatch = false,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'memo': memo,
    'minutes': minutes,
    'referenceTime': referenceTime.toIso8601String(),
    'isStopwatch': isStopwatch,
  };

  static ActiveTimerRecord? fromJson(Map<String, dynamic> json) {
    try {
      return ActiveTimerRecord(
        taskId: json['taskId'] as String,
        memo: json['memo'] as String? ?? '',
        minutes: json['minutes'] as int,
        referenceTime: DateTime.parse(json['referenceTime'] as String),
        isStopwatch: json['isStopwatch'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

class ActiveTimerStore {
  static const _key = 'active_timer_v1';

  static Future<void> save(ActiveTimerRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(record.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<ActiveTimerRecord?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return ActiveTimerRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
