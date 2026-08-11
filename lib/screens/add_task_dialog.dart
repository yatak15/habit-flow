import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_icon.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';

/// 新規タスク作成ダイアログ（例：ピアノ10分レッスン、ギター10分練習）
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _nameController = TextEditingController();
  TaskIconType _selectedIcon = TaskIconType.star;
  int _minutes = 10;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.cream,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '新しいタスク',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '例：ピアノ 10分レッスン',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('アイコンを選択', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              TaskIconPicker(
                selected: _selectedIcon,
                onSelected: (t) => setState(() => _selectedIcon = t),
              ),
              const SizedBox(height: 20),
              const Text('タイマー時間', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minutes.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      activeColor: AppColors.sage,
                      inactiveColor: AppColors.divider,
                      label: '$_minutes分',
                      onChanged: (v) => setState(() => _minutes = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text('$_minutes分', textAlign: TextAlign.right,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) return;
                        final service = context.read<TaskService>();
                        final task = await service.addTask(
                          name: name,
                          iconIndex: _selectedIcon.index,
                          defaultMinutes: _minutes,
                        );
                        if (context.mounted) Navigator.pop(context, task);
                      },
                      child: const Text('追加'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
