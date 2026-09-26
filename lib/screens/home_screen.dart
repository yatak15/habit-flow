import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_flow_widgets.dart';
import 'add_task_dialog.dart';
import 'timer_screen.dart';

const List<String> _kWeekdayKanji = ['月', '火', '水', '木', '金', '土', '日'];

/// タスク実行の記録方法：時間を決めるタイマー／経過時間を測るストップウォッチ／
/// タイマーを使わずチェックだけで記録する「記録のみ」
enum _RecordMode { timer, stopwatch, backfill }

/// ホーム画面："Quiet Momentum" デザイン
/// デフォルト状態：日付・週次モメンタム・本日のタスク一覧
/// 選択状態：継続実績チップ・メモ・タイマー設定・開始 CTA
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Task? _selectedTask;
  final TextEditingController _memoController = TextEditingController();
  int _minutes = 10;
  _RecordMode _recordMode = _RecordMode.timer;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _selectTask(Task task) {
    setState(() {
      if (_selectedTask?.id == task.id) {
        // 再タップで選択解除
        _selectedTask = null;
        _memoController.clear();
      } else {
        _selectedTask = task;
        _memoController.text = task.lastMemo;
        _minutes = task.defaultMinutes;
        _recordMode = _RecordMode.timer;
      }
    });
  }

  Future<void> _openAddTaskDialog() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
    if (task != null) {
      setState(() {
        _selectedTask = task;
        _memoController.text = task.lastMemo;
        _minutes = task.defaultMinutes;
        _recordMode = _RecordMode.timer;
      });
    }
  }

  Future<void> _startTimer() async {
    if (_selectedTask == null) return;
    final isStopwatch = _recordMode == _RecordMode.stopwatch;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          task: _selectedTask!,
          memo: _memoController.text.trim(),
          minutes: isStopwatch ? 0 : _minutes,
          isStopwatch: isStopwatch,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {}); // 継続日数などの表示を更新
    }
  }

  String _shortLabel(String name) {
    final parts = name.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : name;
  }

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final tasks = taskService.tasks;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy年M月d日', 'ja_JP').format(now);
    final weekday = _kWeekdayKanji[now.weekday - 1];
    final eyebrow = '$dateStr · $weekday';

    final selected = _selectedTask;
    // 選択タスクが削除されていた場合のガード
    final selectedStillExists =
        selected != null && tasks.any((t) => t.id == selected.id);
    final activeTask = selectedStillExists
        ? tasks.firstWhere((t) => t.id == selected.id)
        : null;

    final tabBarReserved = HFTabBar.reservedHeight(context);
    final showFixedTimerBar = activeTask != null && !activeTask.isAbstain;
    final bgColor = context.watch<ThemeService>().backgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  0,
                  24,
                  showFixedTimerBar ? 16 : tabBarReserved + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroHeader(
                      eyebrow: eyebrow,
                      title: activeTask == null
                          ? '今日も、\n静かに続ける。'
                          : '${_shortLabel(activeTask.name)}の時間。',
                      titleStyle: activeTask == null
                          ? AppText.heroHome
                          : AppText.heroSelected,
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: activeTask == null ? 32 : 24,
                      ),
                    ),
                    if (activeTask == null) ...[
                      MomentumStrip(
                        weeklyCount: taskService.weeklyExecutionCount,
                        longestStreak: taskService.overallLongestStreak,
                        daysToNextPrize: _daysToNextPrize(
                          taskService.topStreakTask,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Row(
                        children: [
                          Text('本日のタスク', style: AppText.h2Section),
                          const SizedBox(width: 8),
                          Text('${tasks.length}件', style: AppText.subMeta),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTaskStrip(tasks, compact: false),
                      const PromptCard(
                        title: 'タスクを選ぶと始められます',
                        body: 'カードをタップして、メモを書き、タイマーをセット。3ステップで今日の一歩を。',
                      ),
                    ] else ...[
                      _buildTaskStrip(tasks, compact: true),
                      const SizedBox(height: 24),
                      _buildStreakChips(activeTask),
                      const SizedBox(height: 20),
                      _buildProgressMeter(activeTask),
                      const SizedBox(height: 28),
                      if (activeTask.isAbstain) ...[
                        _buildAbstainCheckIn(activeTask),
                      ] else ...[
                        Text(
                          'やることをメモ',
                          style: AppText.cardLabel.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                        _buildMemoField(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            // タイマー時間の設定と開始ボタンは常に画面内に収まるよう、
            // スクロール領域の外（画面下部固定）にまとめて配置する
            if (showFixedTimerBar)
              Container(
                padding: EdgeInsets.fromLTRB(24, 16, 24, tabBarReserved + 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: const Border(
                    top: BorderSide(color: AppColors.line),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeToggle(),
                    const SizedBox(height: 14),
                    if (_recordMode == _RecordMode.timer) ...[
                      _buildTimerSection(),
                      const SizedBox(height: 16),
                      PrimaryCta(
                        label: '$_minutes分のタイマーを開始',
                        onPressed: _startTimer,
                      ),
                    ] else if (_recordMode == _RecordMode.stopwatch) ...[
                      PrimaryCta(
                        label: 'ストップウォッチで記録する',
                        icon: Icons.timer_outlined,
                        onPressed: _startTimer,
                      ),
                    ] else
                      _buildBackfillCheckIn(activeTask),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  int? _daysToNextPrize(Task? task) {
    if (task == null) return null;
    final next = PrizeService.nextPrize(task.currentStreak);
    if (next == null) return null;
    return next.requiredDays - task.currentStreak;
  }

  /// 本日のタスク一覧：3列グリッド（4件目以降は次の行に折り返す）
  Widget _buildTaskStrip(List<Task> tasks, {required bool compact}) {
    const int columns = 3;
    const double spacing = 12;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            ...tasks.map((task) {
              final isSelected = _selectedTask?.id == task.id;
              return TaskCardWidget(
                icon: task.iconType,
                label: task.name,
                streak: task.currentStreak,
                selected: isSelected,
                compact: compact,
                isAbstain: task.isAbstain,
                size: cardSize,
                onTap: () => _selectTask(task),
              );
            }),
            AddTaskCardWidget(
              compact: compact,
              size: cardSize,
              onTap: _openAddTaskDialog,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakChips(Task task) {
    final currentPrize = PrizeService.currentPrize(task.currentStreak);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StreakChip(
          icon: Icons.local_fire_department_outlined,
          label: '継続${task.currentStreak}日',
        ),
        StreakChip(
          icon: task.isAbstain ? Icons.event_available_outlined : Icons.repeat,
          label: task.isAbstain
              ? '記録${task.totalCount}日'
              : '実行${task.totalCount}回',
        ),
        if (currentPrize != null)
          StreakChip(
            icon: currentPrize.icon,
            label: currentPrize.title,
            accent: true,
          ),
      ],
    );
  }

  Widget _buildProgressMeter(Task task) {
    final next = PrizeService.nextPrize(task.currentStreak);
    if (next == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.terraSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.terracotta,
            ),
            const SizedBox(width: 8),
            Text(
              'すべてのプライズを達成しました',
              style: AppText.chipLabel.copyWith(color: AppColors.terracotta),
            ),
          ],
        ),
      );
    }
    final remaining = (next.requiredDays - task.currentStreak).clamp(
      0,
      next.requiredDays,
    );
    final progress = next.requiredDays == 0
        ? 0.0
        : task.currentStreak / next.requiredDays;
    return ProgressMeter(
      progress: progress,
      daysRemaining: remaining,
      nextPrizeTitle: next.title,
    );
  }

  Widget _buildMemoField() {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(18),
      child: TextField(
        controller: _memoController,
        maxLines: null,
        minLines: 2,
        style: AppText.body,
        decoration: const InputDecoration(
          hintText: '例：ダイアトニックコード、指板上の音名',
          hintStyle: TextStyle(
            color: AppColors.inkMuted,
            fontSize: 15,
            height: 1.6,
          ),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }

  /// タイマー／ストップウォッチ／記録のみ、3つの記録方法の切り替えタブ
  Widget _buildModeToggle() {
    return Row(
      children: [
        Expanded(
          child: _modeToggleButton(
            label: 'タイマー',
            icon: Icons.hourglass_bottom,
            selected: _recordMode == _RecordMode.timer,
            onTap: () => setState(() => _recordMode = _RecordMode.timer),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _modeToggleButton(
            label: 'ストップ\nウォッチ',
            icon: Icons.timer_outlined,
            selected: _recordMode == _RecordMode.stopwatch,
            onTap: () => setState(() => _recordMode = _RecordMode.stopwatch),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _modeToggleButton(
            label: '記録のみ',
            icon: Icons.edit_calendar_outlined,
            selected: _recordMode == _RecordMode.backfill,
            onTap: () => setState(() => _recordMode = _RecordMode.backfill),
          ),
        ),
      ],
    );
  }

  Widget _modeToggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageDeep : AppColors.sageBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : AppColors.sageDeep,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.inkSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('タイマー時間', style: AppText.cardLabel.copyWith(fontSize: 13)),
            RichText(
              text: TextSpan(
                style: AppText.timerValue,
                children: [
                  TextSpan(text: '$_minutes'),
                  const TextSpan(
                    text: ' 分',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.inkSub,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: hfSliderTheme(),
          child: Slider(
            value: _minutes.toDouble(),
            min: 5,
            max: 60,
            divisions: 11,
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('5分', style: AppText.microLabel),
              Text('15分', style: AppText.microLabel),
              Text('30分', style: AppText.microLabel),
              Text('60分', style: AppText.microLabel),
            ],
          ),
        ),
      ],
    );
  }

  /// アプリを開けなかった日の記録忘れに備え、タイマーを使わず
  /// 「実行した」ことだけを直近3日分まとめてチェックできるパネル（timedタスク用）
  Widget _buildBackfillCheckIn(Task task) {
    final taskService = context.read<TaskService>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(3, (i) => today.subtract(Duration(days: i)));
    const labels = ['今日', '昨日', '一昨日'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_calendar_outlined,
                size: 15,
                color: AppColors.sageDeep,
              ),
              const SizedBox(width: 6),
              Text(
                '時間を計らずに記録する（2日前まで）',
                style: AppText.cardLabel.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final day = days[i];
              final checked = taskService.isDayCompleted(task.id, day);
              final locked = taskService.hasTimedCompletion(task.id, day);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: GestureDetector(
                    onTap: locked
                        ? null
                        : () async {
                            await taskService.toggleBackfillDay(task.id, day);
                            if (mounted) setState(() {});
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: checked ? AppColors.sageDeep : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            checked ? Icons.check_circle : Icons.circle_outlined,
                            size: 20,
                            color: checked ? Colors.white : AppColors.sageDeep,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            locked ? '${labels[i]}・実行済み' : labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: checked ? Colors.white : AppColors.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 「やめたい習慣」用：直近3日分をまとめてチェックできるパネル
  /// 前日の記録忘れに対応できるよう、今日・昨日・一昨日をまとめて表示する。
  Widget _buildAbstainCheckIn(Task task) {
    final taskService = context.read<TaskService>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(3, (i) => today.subtract(Duration(days: i)));
    const labels = ['今日', '昨日', '一昨日'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'できなかった／やらなかった日をチェック',
            style: AppText.cardLabel.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '前日以前の記録忘れに備え、直近3日分をまとめてチェックできます',
            style: AppText.subMeta,
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (i) {
              final day = days[i];
              final checked = taskService.isAbstainDayMarked(task.id, day);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: GestureDetector(
                    onTap: () async {
                      await taskService.toggleAbstainDay(task.id, day);
                      if (mounted) setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: checked
                            ? AppColors.slateDeep
                            : AppColors.slateBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            checked
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 20,
                            color: checked ? Colors.white : AppColors.slateDeep,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: checked ? Colors.white : AppColors.inkSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
