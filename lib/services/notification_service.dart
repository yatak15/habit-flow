import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// タイマー終了をアプリがバックグラウンドにあっても通知するためのローカル通知サービス。
/// 通知IDは常に同じ値を使い、常に「今動いているタイマーは1つだけ」という前提で
/// 予約・取消を行う（同時に複数のタイマーを走らせるUIが存在しないため）。
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int timerNotificationId = 1001;
  static const String timerFinishedPayloadPrefix = 'timer_finished:';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'timer_finished',
        'タイマー終了通知',
        description: '習慣タイマーの終了をお知らせします',
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// [endTime]にタイマー終了通知を予約する。既存の予約があれば置き換える。
  Future<void> scheduleTimerFinished({
    required String taskId,
    required String taskName,
    required DateTime endTime,
  }) async {
    await init();
    await cancelTimerFinished();
    // タイマーがすでに終了時刻を過ぎている場合は予約しない
    if (!endTime.isAfter(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: timerNotificationId,
      title: taskName,
      body: 'タイマー終了！お疲れさまでした',
      scheduledDate: tz.TZDateTime.from(endTime, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'timer_finished',
          'タイマー終了通知',
          channelDescription: '習慣タイマーの終了をお知らせします',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
        macOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$timerFinishedPayloadPrefix$taskId',
    );
  }

  Future<void> cancelTimerFinished() async {
    await _plugin.cancel(id: timerNotificationId);
  }
}
