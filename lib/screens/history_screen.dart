import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';
import '../widgets/habit_flow_widgets.dart';
import 'add_task_dialog.dart';

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
    final bgColor = context.watch<ThemeService>().backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
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
                        cumulativeMinutes: _cumulativeMinutesFor(
                          taskService,
                          task,
                        ),
                        emphasizeExecution: _segment != _HistorySegment.all,
                        onReset: () => _confirmReset(context, taskService, task),
                        onEdit: () => _openEditDialog(context, task),
                        onDelete: () =>
                            _confirmDelete(context, taskService, task),
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

  Future<void> _openEditDialog(BuildContext context, Task task) async {
    await showDialog<Task>(
      context: context,
      builder: (_) => AddTaskDialog(editingTask: task),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    TaskService service,
    Task task,
  ) async {
    final bgColor = context.read<ThemeService>().backgroundColor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('記録をリセット'),
        content: Text(
          task.isAbstain
              ? '「${task.name}」の継続日数・記録日数・最長記録と、チェック履歴をすべて削除します。\n'
                    'この操作は取り消せません。'
              : '「${task.name}」の継続日数・実行回数・累積時間・最長記録をすべて0に戻します。\n'
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

  /// タスクそのものを完全に削除する（実行ログも含めて元に戻せない）
  Future<void> _confirmDelete(
    BuildContext context,
    TaskService service,
    Task task,
  ) async {
    final bgColor = context.read<ThemeService>().backgroundColor;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('タスクを削除'),
        content: Text(
          '「${task.name}」を履歴ごと完全に削除します。\nこの操作は取り消せません。',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除する', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.deleteTask(task.id);
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
  final int cumulativeMinutes;
  final bool emphasizeExecution;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _HistoryRowCard({
    required this.task,
    required this.executionCount,
    required this.cumulativeMinutes,
    required this.emphasizeExecution,
    required this.onReset,
    required this.onEdit,
    required this.onDelete,
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
                backgroundColor: task.isAbstain
                    ? AppColors.slateBg
                    : AppColors.sageBg,
                iconColor: task.isAbstain
                    ? AppColors.slateDeep
                    : AppColors.sageDeep,
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
              _buildMoreMenu(context),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 18),
          _buildMetrics(),
        ],
      ),
    );
  }

  /// CURRENT（累計の継続日数）は常に全期間の値。
  /// 「今週」「今月」タブでは期間内の実行回数の方が意味のある数値なので、
  /// そちらを大きく表示し、CURRENTは他の数値と同じ大きさで添える。
  Widget _buildMetrics() {
    final currentMetric = _metric(
      label: 'CURRENT',
      value: '${task.currentStreak}',
      suffix: '日',
      hero: !emphasizeExecution,
    );
    final executionMetric = _metric(
      label: task.isAbstain ? '記録' : '実行',
      value: '$executionCount',
      suffix: task.isAbstain ? '日' : '回',
      hero: emphasizeExecution,
    );
    final bestMetric = _metric(
      label: '最長',
      value: '${task.bestStreak}',
      suffix: '日',
      hero: false,
    );

    final heroMetric = emphasizeExecution ? executionMetric : currentMetric;
    final otherMetric = emphasizeExecution ? currentMetric : executionMetric;

    // abstainタスクはタイマーを使わないため、累計時間は意味を持たず表示しない
    final subMetrics = task.isAbstain
        ? [otherMetric, bestMetric]
        : [
            otherMetric,
            bestMetric,
            _metric(
              label: '累計時間',
              value: _formatMinutes(cumulativeMinutes),
              suffix: '',
              hero: false,
            ),
            if (task.trackFitness) ...[
              _metric(
                label: '累計距離',
                value: (task.cumulativeDistanceMeters / 1000).toStringAsFixed(
                  1,
                ),
                suffix: 'km',
                hero: false,
              ),
              _metric(
                label: '累計歩数',
                value: '${task.cumulativeSteps}',
                suffix: '歩',
                hero: false,
              ),
            ],
          ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        heroMetric,
        const SizedBox(width: 20),
        Expanded(
          child: Wrap(
            spacing: 20,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: subMetrics,
          ),
        ),
      ],
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required String suffix,
    required bool hero,
  }) {
    return hero
        ? _heroMetric(label, value, suffix)
        : _subMetric(label, value, suffix);
  }

  Widget _buildMoreMenu(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'その他の操作',
        icon: const Icon(
          Icons.more_vert,
          size: 18,
          color: AppColors.inkMuted,
        ),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit();
              break;
            case 'reset':
              onReset();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: AppColors.inkSub),
                SizedBox(width: 10),
                Text('編集'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reset',
            child: Row(
              children: [
                Icon(Icons.restart_alt, size: 18, color: AppColors.inkSub),
                SizedBox(width: 10),
                Text('リセット'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                SizedBox(width: 10),
                Text('削除', style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ],
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
