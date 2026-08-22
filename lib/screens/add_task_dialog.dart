import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_icon.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';
import '../widgets/habit_flow_widgets.dart';

/// 新規タスク作成ダイアログ（例：ピアノ10分レッスン、ギター10分練習）
/// "Quiet Momentum" デザインに合わせたスタイル
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
      backgroundColor: AppColors.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新しいタスク', style: AppText.h2Section),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  controller: _nameController,
                  style: AppText.body.copyWith(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: '例：ピアノ 10分レッスン',
                    hintStyle: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('アイコンを選択', style: AppText.subMeta.copyWith(fontSize: 13)),
              const SizedBox(height: 12),
              TaskIconPicker(
                selected: _selectedIcon,
                onSelected: (t) => setState(() => _selectedIcon = t),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('タイマー時間', style: AppText.subMeta.copyWith(fontSize: 13)),
                  Text(
                    '$_minutes分',
                    style: AppText.cardLabel.copyWith(fontSize: 14),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'キャンセル',
                        style: AppText.cardLabel.copyWith(
                          color: AppColors.inkSub,
                        ),
                      ),
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
