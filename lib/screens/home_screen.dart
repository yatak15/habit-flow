import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_flow_widgets.dart';
import 'add_task_dialog.dart';
import 'timer_screen.dart';

const List<String> _kWeekdayKanji = ['月', '火', '水', '木', '金', '土', '日'];

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
      });
    }
  }

  Future<void> _startTimer() async {
    if (_selectedTask == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          task: _selectedTask!,
          memo: _memoController.text.trim(),
          minutes: _minutes,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                tabBarReserved + (activeTask != null ? 88 : 20),
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
                    Text(
                      'やることをメモ',
                      style: AppText.cardLabel.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    _buildMemoField(),
                    const SizedBox(height: 28),
                    _buildTimerSection(),
                  ],
                ],
              ),
            ),
            if (activeTask != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: tabBarReserved,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.bg.withValues(alpha: 0), AppColors.bg],
                      stops: const [0, 0.4],
                    ),
                  ),
                  child: PrimaryCta(
                    label: '$_minutes分のタイマーを開始',
                    onPressed: _startTimer,
                  ),
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

  Widget _buildTaskStrip(List<Task> tasks, {required bool compact}) {
    final double height = compact ? 108 : 132;
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          ...tasks.map((task) {
            final isSelected = _selectedTask?.id == task.id;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TaskCardWidget(
                icon: task.iconType,
                label: task.name,
                streak: task.currentStreak,
                selected: isSelected,
                compact: compact,
                onTap: () => _selectTask(task),
              ),
            );
          }),
          AddTaskCardWidget(compact: compact, onTap: _openAddTaskDialog),
        ],
      ),
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
        StreakChip(icon: Icons.repeat, label: '実行${task.totalCount}回'),
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
}
