import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../services/active_timer_store.dart';
import '../services/notification_service.dart';
import '../services/fitness_tracker.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';

enum TimerState { ready, running, paused, finished }

/// タイマー実行画面：セット→スタート→終了後クリアマーク
/// アプリをバックグラウンドにしても実際の経過時間を基に継続動作し、
/// 終了時刻をローカル通知として予約することで、他のアプリを使っていても
/// 終了に気づける（[resumeEndTime]/[resumeStartTime]が渡された場合は
/// アプリ再起動後の復元表示）。
/// [isStopwatch]がtrueの場合は目標時間を決めず0からカウントアップする
/// ストップウォッチモードになる（終了通知の予約は行わない）。
class TimerScreen extends StatefulWidget {
  final Task task;
  final String memo;
  final int minutes;
  final bool isStopwatch;
  final DateTime? resumeEndTime;
  final DateTime? resumeStartTime;

  const TimerScreen({
    super.key,
    required this.task,
    required this.memo,
    required this.minutes,
    this.isStopwatch = false,
    this.resumeEndTime,
    this.resumeStartTime,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  static const _prefVibrateKey = 'timer_vibrate_on_finish';
  static const _prefSoundKey = 'timer_sound_on_finish';
  static const _prefGpsKey = 'run_gps_enabled';
  static const _finishEffectDuration = Duration(seconds: 5);
  static const _finishEffectTick = Duration(milliseconds: 400);

  late int _totalSeconds;
  late int _remainingSeconds;
  int _elapsedSeconds = 0;
  DateTime? _endTime;
  DateTime? _startTime;
  Timer? _timer;
  Timer? _finishEffectTimer;
  final AudioPlayer _finishSoundPlayer = AudioPlayer();
  TimerState _state = TimerState.ready;
  bool _cleared = false;
  bool _vibrateOnFinish = true;
  bool _soundOnFinish = true;
  bool _gpsEnabled = true;
  FitnessTracker? _fitnessTracker;
  double _distanceMeters = 0;
  int _steps = 0;

  bool get _isStopwatch => widget.isStopwatch;
  bool get _trackFitness => widget.task.trackFitness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = widget.minutes * 60;
    _remainingSeconds = _totalSeconds;
    _loadFinishPrefs();
    _finishSoundPlayer.setPlayerMode(PlayerMode.lowLatency);
    _finishSoundPlayer.setReleaseMode(ReleaseMode.stop);
    NotificationService.instance.requestPermissions();

    if (_trackFitness) {
      _fitnessTracker = FitnessTracker(
        onUpdate: (distance, steps) {
          if (!mounted) return;
          setState(() {
            _distanceMeters = distance;
            _steps = steps;
          });
        },
      );
    }

    if (_isStopwatch) {
      final resumeStartTime = widget.resumeStartTime;
      if (resumeStartTime != null) {
        _elapsedSeconds = DateTime.now()
            .difference(resumeStartTime)
            .inSeconds
            .clamp(0, 24 * 60 * 60);
        _startTime = resumeStartTime;
        _state = TimerState.running;
        _runStopwatchTicker();
        // アプリ再起動をまたいだ場合、距離・歩数の積算は復元できないため
        // ここから新たに計測を開始する
        _startFitnessTrackingIfNeeded();
      }
      return;
    }

    final resumeEndTime = widget.resumeEndTime;
    if (resumeEndTime != null) {
      final remaining = resumeEndTime.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _remainingSeconds = 0;
        _state = TimerState.finished;
        // 通知は既に発火済みのはずなので、保存済みの状態のみ片付ける
        ActiveTimerStore.clear();
        NotificationService.instance.cancelTimerFinished();
      } else {
        _remainingSeconds = remaining.clamp(0, _totalSeconds);
        _endTime = resumeEndTime;
        _state = TimerState.running;
        _runTicker();
        _startFitnessTrackingIfNeeded();
      }
    }
  }

  Future<void> _loadFinishPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _vibrateOnFinish = prefs.getBool(_prefVibrateKey) ?? true;
      _soundOnFinish = prefs.getBool(_prefSoundKey) ?? true;
      _gpsEnabled = prefs.getBool(_prefGpsKey) ?? true;
    });
  }

  Future<void> _setGpsEnabled(bool value) async {
    setState(() => _gpsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGpsKey, value);
  }

  /// 歩数・（有効なら）GPSの計測を開始する。位置情報の許可がない場合は
  /// 歩数のみで続行する。
  Future<void> _startFitnessTrackingIfNeeded() async {
    final tracker = _fitnessTracker;
    if (tracker == null) return;
    var gps = _gpsEnabled;
    if (gps) {
      final granted = await tracker.requestLocationPermission();
      if (!granted) gps = false;
    }
    await tracker.start(gpsEnabled: gps);
  }

  Future<void> _setVibrateOnFinish(bool value) async {
    setState(() => _vibrateOnFinish = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefVibrateKey, value);
  }

  Future<void> _setSoundOnFinish(bool value) async {
    setState(() => _soundOnFinish = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefSoundKey, value);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _finishEffectTimer?.cancel();
    _finishSoundPlayer.dispose();
    // 画面を離れる（戻る操作）＝タイマーを手放す、とみなしバックグラウンド用の
    // 予約・保存済み状態を片付ける（未保存でも呼び出し自体は無害）。
    // OSによるバックグラウンド化ではdispose()は呼ばれないため、
    // その間は予約・保存が維持され継続動作する。
    NotificationService.instance.cancelTimerFinished();
    ActiveTimerStore.clear();
    _fitnessTracker?.pause();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _state != TimerState.running) {
      return;
    }
    if (_isStopwatch) {
      _syncFromStartTime();
    } else if (_endTime != null) {
      _syncFromEndTime(triggerEffectIfFinished: false);
    }
  }

  /// 実時間（終了予定時刻）から残り秒数を再計算する。
  /// アプリがバックグラウンドで停止していた間もズレなく反映できる。
  void _syncFromEndTime({required bool triggerEffectIfFinished}) {
    final endTime = _endTime;
    if (endTime == null || !mounted) return;
    final remaining = endTime.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      setState(() {
        _remainingSeconds = 0;
        _state = TimerState.finished;
      });
      _clearActiveRecord();
      _fitnessTracker?.pause();
      if (triggerEffectIfFinished) {
        _onFinished();
      }
    } else if (remaining != _remainingSeconds) {
      setState(() => _remainingSeconds = remaining);
    }
  }

  /// 実時間（開始時刻）から経過秒数を再計算する（ストップウォッチ用）。
  void _syncFromStartTime() {
    final startTime = _startTime;
    if (startTime == null || !mounted) return;
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    if (elapsed != _elapsedSeconds) {
      setState(() => _elapsedSeconds = elapsed);
    }
  }

  void _start() {
    _startFitnessTrackingIfNeeded();
    if (_isStopwatch) {
      final startTime = DateTime.now().subtract(
        Duration(seconds: _elapsedSeconds),
      );
      setState(() {
        _state = TimerState.running;
        _startTime = startTime;
      });
      _saveActiveRecord(startTime);
      _runStopwatchTicker();
      return;
    }
    final endTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    setState(() {
      _state = TimerState.running;
      _endTime = endTime;
    });
    _saveActiveRecord(endTime);
    _runTicker();
  }

  void _runTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncFromEndTime(triggerEffectIfFinished: true),
    );
  }

  void _runStopwatchTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncFromStartTime());
  }

  void _pause() {
    _timer?.cancel();
    setState(() {
      _state = TimerState.paused;
      _endTime = null;
      _startTime = null;
    });
    _clearActiveRecord();
    _fitnessTracker?.pause();
  }

  void _resume() => _start();

  void _reset() {
    _timer?.cancel();
    _fitnessTracker?.reset();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _elapsedSeconds = 0;
      _state = TimerState.ready;
      _endTime = null;
      _startTime = null;
      _distanceMeters = 0;
      _steps = 0;
    });
    _clearActiveRecord();
  }

  /// ストップウォッチを止めて「クリアを記録する」画面へ進む
  void _finishStopwatch() {
    _timer?.cancel();
    setState(() {
      _state = TimerState.finished;
      _startTime = null;
    });
    _clearActiveRecord();
    _fitnessTracker?.pause();
  }

  Future<void> _saveActiveRecord(DateTime referenceTime) async {
    await ActiveTimerStore.save(
      ActiveTimerRecord(
        taskId: widget.task.id,
        memo: widget.memo,
        minutes: widget.minutes,
        referenceTime: referenceTime,
        isStopwatch: _isStopwatch,
      ),
    );
    // ストップウォッチには決まった終了時刻がないため、終了通知は予約しない
    if (!_isStopwatch) {
      await NotificationService.instance.scheduleTimerFinished(
        taskId: widget.task.id,
        taskName: widget.task.name,
        endTime: referenceTime,
      );
    }
  }

  Future<void> _clearActiveRecord() async {
    await ActiveTimerStore.clear();
    await NotificationService.instance.cancelTimerFinished();
  }

  Future<void> _onFinished() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('タイマー終了！お疲れさまでした'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          // 「クリアを記録する」ボタンと重ならないよう、その上に浮かせて表示する
          margin: const EdgeInsets.fromLTRB(32, 0, 32, 96),
        ),
      );
    }
    _playFinishEffect();
  }

  /// 終了時、設定に応じて5秒間バイブレーション・サウンドを繰り返す
  void _playFinishEffect() {
    if (!_vibrateOnFinish && !_soundOnFinish) return;
    _finishEffectTimer?.cancel();
    final totalTicks =
        _finishEffectDuration.inMilliseconds ~/ _finishEffectTick.inMilliseconds;
    int tick = 0;
    void fire() {
      if (_vibrateOnFinish) HapticFeedback.heavyImpact();
      // iOSのSystemSound.play(SystemSoundType.alert)は音が鳴らないため、
      // 同梱のアラート音をAudioPlayerで再生する
      if (_soundOnFinish) {
        _finishSoundPlayer.stop();
        _finishSoundPlayer.play(AssetSource('sounds/finish_alert.wav'));
      }
    }

    fire();
    _finishEffectTimer = Timer.periodic(_finishEffectTick, (t) {
      tick += 1;
      if (tick >= totalTicks) {
        t.cancel();
        return;
      }
      fire();
    });
  }

  int get _recordedMinutes =>
      _isStopwatch ? (_elapsedSeconds / 60).round() : widget.minutes;

  Future<void> _markClear() async {
    if (_cleared) return;
    final service = context.read<TaskService>();
    await service.completeTask(
      widget.task,
      memo: widget.memo,
      minutes: _recordedMinutes,
      distanceMeters: _trackFitness ? _distanceMeters : null,
      steps: _trackFitness ? _steps : null,
    );
    setState(() => _cleared = true);

    if (!mounted) return;
    final updatedStreak = widget.task.currentStreak;
    final achieved = PrizeService.justAchieved(updatedStreak);
    final dialogBgColor = context.read<ThemeService>().backgroundColor;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.sageDark),
            const SizedBox(width: 8),
            const Text('クリア！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '継続日数： $updatedStreak 日',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            Text(
              '総実行回数： ${widget.task.totalCount} 回',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (_trackFitness) ...[
              Text(
                '距離： ${(_distanceMeters / 1000).toStringAsFixed(2)} km ・ 歩数： $_steps 歩',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
            if (achieved != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(achieved.icon, color: AppColors.accentGold, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'プライズ獲得：${achieved.title}',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final double? progress = _isStopwatch
        ? (_state == TimerState.running
              ? null
              : (_state == TimerState.finished ? 1.0 : 0.0))
        : (_totalSeconds == 0 ? 0.0 : 1 - (_remainingSeconds / _totalSeconds));
    final displaySeconds = _isStopwatch ? _elapsedSeconds : _remainingSeconds;
    final finished = _state == TimerState.finished;
    // 完了時は一目でわかるよう、他の画面では使わない暖色（テラコッタ系）に大きく変える
    final bgColor = finished
        ? AppColors.terraSoft
        : context.watch<ThemeService>().backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(title: Text(widget.task.name), backgroundColor: bgColor),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: bgColor,
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              TaskIconWidget(iconType: widget.task.iconType, size: 56),
              const SizedBox(height: 8),
              if (widget.memo.isNotEmpty)
                Text(
                  widget.memo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.sage,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(displaySeconds),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _state == TimerState.finished
                              ? '完了'
                              : (_isStopwatch ? '経過時間' : '${widget.minutes}分'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_trackFitness) ...[
                const SizedBox(height: 20),
                _buildFitnessStats(),
              ],
              const Spacer(),
              if (_state == TimerState.ready && _trackFitness) ...[
                _buildGpsToggle(),
                const SizedBox(height: 12),
              ],
              if (_state == TimerState.ready && !_isStopwatch) ...[
                _buildFinishEffectToggles(),
                const SizedBox(height: 12),
              ],
              if (_state != TimerState.finished) _buildControls(),
              if (_isStopwatch &&
                  (_state == TimerState.running ||
                      _state == TimerState.paused)) ...[
                const SizedBox(height: 12),
                _buildStopwatchFinishButton(),
              ],
              if (_state == TimerState.finished) _buildClearButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildFitnessStats() {
    final km = _distanceMeters / 1000;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _fitnessStatChip(
          icon: Icons.route_outlined,
          label: '${km.toStringAsFixed(2)} km',
        ),
        const SizedBox(width: 12),
        _fitnessStatChip(icon: Icons.directions_walk, label: '$_steps 歩'),
      ],
    );
  }

  Widget _fitnessStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.sageDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'GPSで距離を記録する',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        subtitle: const Text(
          'オフにすると歩数のみ記録します',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        value: _gpsEnabled,
        activeColor: AppColors.sageDeep,
        onChanged: _setGpsEnabled,
      ),
    );
  }

  Widget _buildFinishEffectToggles() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '終了時にバイブレーション（5秒）',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            value: _vibrateOnFinish,
            activeColor: AppColors.sageDeep,
            onChanged: _setVibrateOnFinish,
          ),
          const Divider(height: 1, color: AppColors.divider),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '終了時にサウンド（5秒）',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            value: _soundOnFinish,
            activeColor: AppColors.sageDeep,
            onChanged: _setSoundOnFinish,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_state == TimerState.ready) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('スタート'),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.replay, color: AppColors.textSecondary),
            label: const Text(
              'リセット',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: AppColors.divider),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _state == TimerState.running ? _pause : _resume,
            icon: Icon(
              _state == TimerState.running ? Icons.pause : Icons.play_arrow,
            ),
            label: Text(_state == TimerState.running ? '一時停止' : '再開'),
          ),
        ),
      ],
    );
  }

  Widget _buildStopwatchFinishButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _finishStopwatch,
        icon: const Icon(Icons.flag_outlined, color: AppColors.sageDeep),
        label: const Text(
          '終了して記録する',
          style: TextStyle(color: AppColors.sageDeep),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.sageDeep),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cleared ? null : _markClear,
        icon: Icon(_cleared ? Icons.check_circle : Icons.flag_outlined),
        label: Text(_cleared ? '記録済み' : 'クリアを記録する'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
      ),
    );
  }
}
