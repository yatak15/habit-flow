import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';
import '../widgets/habit_flow_widgets.dart';

enum _HistorySegment { all, week, month }

/// 履歴画面："Quiet Momentum" デザイン
/// Segmented Control（すべて / 今週 / 今月）+ 非対称 Hero Metric（継続日数を強調）
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistorySegment _segment = _HistorySegment.all;

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final tasks = taskService.tasks;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: tasks.isEmpty
            ? _buildEmpty()
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  HFTabBar.reservedHeight(context) + 20,
                ),
                children: [
                  const HeroHeader(
                    eyebrow: 'JOURNAL',
                    title: 'これまでの\n積み重ね。',
                    titleStyle: AppText.heroHistory,
                    padding: EdgeInsets.only(top: 4, bottom: 24),
                  ),
                  _buildSegmentedControl(),
                  const SizedBox(height: 24),
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _HistoryRowCard(
                        task: task,
                        executionCount: _executionCountFor(taskService, task),
                        currentStreak: _currentStreakFor(taskService, task),
                        cumulativeMinutes: _cumulativeMinutesFor(
                          taskService,
                          task,
                        ),
                        onReset: () => _confirmReset(context, taskService, task),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_outlined, size: 40, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            Text('まだ記録がありません', style: AppText.subMeta.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  int _executionCountFor(TaskService service, Task task) {
    switch (_segment) {
      case _HistorySegment.all:
        return task.totalCount;
      case _HistorySegment.week:
        return service.logsForTaskSince(task.id, service.startOfWeek).length;
      case _HistorySegment.month:
        return service.logsForTaskSince(task.id, service.startOfMonth).length;
    }
  }

  /// タブ（すべて/今週/今月）に応じた継続日数
  /// 「今週」「今月」は期間の開始日をまたいだ分を含めない（要修正報告 #4 対応）
  int _currentStreakFor(TaskService service, Task task) {
    switch (_segment) {
      case _HistorySegment.all:
        return task.currentStreak;
      case _HistorySegment.week:
        return service.streakWithinPeriod(task.id, service.startOfWeek);
      case _HistorySegment.month:
        return service.streakWithinPeriod(task.id, service.startOfMonth);
    }
  }

  int _cumulativeMinutesFor(TaskService service, Task task) {
    switch (_segment) {
      case _HistorySegment.all:
        return task.cumulativeMinutes;
      case _HistorySegment.week:
        return service.cumulativeMinutesSince(task.id, service.startOfWeek);
      case _HistorySegment.month:
        return service.cumulativeMinutesSince(task.id, service.startOfMonth);
    }
  }

  Future<void> _confirmReset(
    BuildContext context,
    TaskService service,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('記録をリセット'),
        content: Text(
          '「${task.name}」の継続日数・実行回数・累積時間・最長記録をすべて0に戻します。\n'
          'この操作は取り消せません（履歴の完了ログは保持されます）。',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'リセットする',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.resetTask(task.id);
    }
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _segmentButton('すべて', _HistorySegment.all),
          _segmentButton('今週', _HistorySegment.week),
          _segmentButton('今月', _HistorySegment.month),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, _HistorySegment value) {
    final active = _segment == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.sageDeep : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.inkSub,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryRowCard extends StatelessWidget {
  final Task task;
  final int executionCount;
  final int currentStreak;
  final int cumulativeMinutes;
  final VoidCallback onReset;
  const _HistoryRowCard({
    required this.task,
    required this.executionCount,
    required this.currentStreak,
    required this.cumulativeMinutes,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final currentPrize = PrizeService.currentPrize(task.currentStreak);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TaskIconWidget(
                iconType: task.iconType,
                size: 52,
                radius: 16,
                backgroundColor: AppColors.sageBg,
                iconColor: AppColors.sageDeep,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.name, style: AppText.rowLabel),
                    if (task.lastCompletedDate != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '最終実施 ${DateFormat('M月d日').format(task.lastCompletedDate!)}',
                        style: AppText.subMeta,
                      ),
                    ],
                  ],
                ),
              ),
              if (currentPrize != null) ...[
                _buildPrizeBadge(currentPrize.title),
                const SizedBox(width: 4),
              ],
              _buildResetButton(context),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _heroMetric('CURRENT', '$currentStreak', '日'),
              const SizedBox(width: 20),
              _subMetric('実行', '$executionCount', '回'),
              const SizedBox(width: 20),
              _subMetric('最長', '${task.bestStreak}', '日'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '累計時間 ${_formatMinutes(cumulativeMinutes)}',
            style: AppText.subMeta,
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: const Icon(
          Icons.restart_alt,
          size: 18,
          color: AppColors.inkMuted,
        ),
        tooltip: 'この記録をリセット',
        onPressed: onReset,
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return '0分';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '$minutes分';
    if (minutes == 0) return '$hours時間';
    return '$hours時間$minutes分';
  }

  Widget _buildPrizeBadge(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.terraSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco, size: 13, color: AppColors.terracotta),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.terracotta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String label, String value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.microLabel),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: AppText.historyHeroNumber.copyWith(
              color: AppColors.sageDeep,
            ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: suffix,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.inkSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subMetric(String label, String value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.microLabel),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            style: AppText.historySubMetric,
            children: [
              TextSpan(text: value),
              const TextSpan(
                text: '',
                style: TextStyle(fontSize: 12, color: AppColors.inkSub),
              ),
              TextSpan(
                text: suffix,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
