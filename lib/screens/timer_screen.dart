import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';

enum TimerState { ready, running, paused, finished }

/// タイマー実行画面：セット→スタート→終了後クリアマーク
class TimerScreen extends StatefulWidget {
  final Task task;
  final String memo;
  final int minutes;

  const TimerScreen({
    super.key,
    required this.task,
    required this.memo,
    required this.minutes,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  TimerState _state = TimerState.ready;
  bool _cleared = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.minutes * 60;
    _remainingSeconds = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _state = TimerState.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 1) {
        t.cancel();
        setState(() {
          _remainingSeconds = 0;
          _state = TimerState.finished;
        });
        _onFinished();
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _state = TimerState.paused);
  }

  void _resume() => _start();

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalSeconds;
      _state = TimerState.ready;
    });
  }

  Future<void> _onFinished() async {
    // タイマー終了音的な役割としてバイブ等は省略、UIで通知
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('タイマー終了！お疲れさまでした')));
    }
  }

  Future<void> _markClear() async {
    if (_cleared) return;
    final service = context.read<TaskService>();
    await service.completeTask(
      widget.task,
      memo: widget.memo,
      minutes: widget.minutes,
    );
    setState(() => _cleared = true);

    if (!mounted) return;
    final updatedStreak = widget.task.currentStreak;
    final achieved = PrizeService.justAchieved(updatedStreak);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
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
    final progress = _totalSeconds == 0
        ? 0.0
        : 1 - (_remainingSeconds / _totalSeconds);

    return Scaffold(
      appBar: AppBar(title: Text(widget.task.name)),
      body: SafeArea(
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
                          _formatTime(_remainingSeconds),
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
                              : '${widget.minutes}分',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_state != TimerState.finished) _buildControls(),
              if (_state == TimerState.finished) _buildClearButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
