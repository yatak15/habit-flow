import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/prize_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';

/// 履歴ページ：どのタスクを何回行ったかの一覧
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final tasks = taskService.tasks;

    return Scaffold(
      appBar: AppBar(title: const Text('履歴')),
      body: tasks.isEmpty
          ? const Center(
              child: Text('まだタスクがありません', style: TextStyle(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _TaskHistoryCard(task: tasks[index]),
            ),
    );
  }
}

class _TaskHistoryCard extends StatelessWidget {
  final Task task;
  const _TaskHistoryCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final currentPrize = PrizeService.currentPrize(task.currentStreak);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TaskIconWidget(iconType: task.iconType, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.name,
                        style: const TextStyle(
                            fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    if (task.lastCompletedDate != null)
                      Text(
                        '最終実施：${DateFormat('M月d日').format(task.lastCompletedDate!)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (currentPrize != null)
                Icon(currentPrize.icon, color: AppColors.accentGold, size: 26),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _MetricBlock(label: '実行回数', value: '${task.totalCount}回'),
              const SizedBox(width: 24),
              _MetricBlock(label: '現在の継続', value: '${task.currentStreak}日'),
              const SizedBox(width: 24),
              _MetricBlock(label: '最長継続', value: '${task.bestStreak}日'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 17, color: AppColors.sageDark, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
