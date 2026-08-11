import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';
import 'add_task_dialog.dart';
import 'timer_screen.dart';

/// ホーム画面：1.起動 → 2.タスク選択 → 3.メモ入力 → 4.タイマーセット
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
      _selectedTask = task;
      _memoController.text = task.lastMemo;
      _minutes = task.defaultMinutes;
    });
  }

  Future<void> _openAddTaskDialog() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
    if (task != null) {
      _selectTask(task);
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

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final tasks = taskService.tasks;
    final today = DateFormat('yyyy年M月d日 (E)', 'ja_JP').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Flow', style: TextStyle(letterSpacing: 1)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(today, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              const Text('本日のタスク', style: TextStyle(fontSize: 18, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildTaskList(tasks),
              const SizedBox(height: 28),
              if (_selectedTask != null) _buildDetailSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...tasks.map((task) {
            final isSelected = _selectedTask?.id == task.id;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _selectTask(task),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.sage : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.sage : AppColors.divider,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TaskIconWidget(
                        iconType: task.iconType,
                        size: 36,
                        backgroundColor: isSelected ? Colors.white : AppColors.sageLight,
                        iconColor: isSelected ? AppColors.sage : AppColors.sageDark,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          task.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: _openAddTaskDialog,
            child: Container(
              width: 96,
              decoration: BoxDecoration(
                color: AppColors.creamDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
              ),
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.textSecondary),
                  SizedBox(height: 6),
                  Text('追加', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection() {
    final task = _selectedTask!;
    final nextPrize = PrizeService.nextPrize(task.currentStreak);
    final currentPrize = PrizeService.currentPrize(task.currentStreak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatChip(
              icon: Icons.local_fire_department_outlined,
              label: '継続 ${task.currentStreak}日',
            ),
            const SizedBox(width: 10),
            _StatChip(
              icon: Icons.repeat,
              label: '実行 ${task.totalCount}回',
            ),
            if (currentPrize != null) ...[
              const SizedBox(width: 10),
              _StatChip(
                icon: currentPrize.icon,
                label: currentPrize.title,
                color: AppColors.accentGold,
              ),
            ],
          ],
        ),
        if (nextPrize != null) ...[
          const SizedBox(height: 8),
          Text(
            '次のプライズまで あと ${nextPrize.requiredDays - task.currentStreak}日（${nextPrize.title}）',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        const Text('やることをメモ', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        TextField(
          controller: _memoController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '例：バイエル No.32、コード進行の練習',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('タイマー時間', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
            const Spacer(),
            Text('$_minutes 分', style: const TextStyle(fontSize: 15, color: AppColors.sageDark)),
          ],
        ),
        Slider(
          value: _minutes.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          activeColor: AppColors.sage,
          inactiveColor: AppColors.divider,
          onChanged: (v) => setState(() => _minutes = v.round()),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('タイマーをセットしてスタート'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.sageDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: c),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: c)),
        ],
      ),
    );
  }
}
