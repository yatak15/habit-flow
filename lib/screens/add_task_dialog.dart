import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/task_icon.dart';
import '../services/task_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_icon_widget.dart';
import '../widgets/habit_flow_widgets.dart';

/// 新規タスク作成ダイアログ（例：ピアノ10分レッスン、ギター10分練習）
/// "Quiet Momentum" デザインに合わせたスタイル
class AddTaskDialog extends StatefulWidget {
  /// 指定すると「編集モード」になり、このタスクの内容を初期値として表示する
  final Task? editingTask;

  const AddTaskDialog({super.key, this.editingTask});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late final TextEditingController _nameController;
  late TaskIconType _selectedIcon;
  late int _minutes;
  late TaskMode _mode;
  late bool _trackFitness;

  bool get _isEditing => widget.editingTask != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingTask;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _selectedIcon = editing?.iconType ?? TaskIconType.star;
    _minutes = editing?.defaultMinutes ?? 10;
    _mode = editing?.mode ?? TaskMode.timed;
    _trackFitness = editing?.trackFitness ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.watch<ThemeService>().backgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'タスクを編集' : '新しいタスク',
                style: AppText.h2Section,
              ),
              const SizedBox(height: 20),
              if (!_isEditing) ...[
                _buildModeSelector(),
                const SizedBox(height: 20),
              ],
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
              if (_mode == TaskMode.timed) ...[
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'タイマー時間',
                      style: AppText.subMeta.copyWith(fontSize: 13),
                    ),
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      'ランニングなど：距離・歩数を記録する',
                      style: AppText.cardLabel.copyWith(fontSize: 13),
                    ),
                    subtitle: Text(
                      '実行中にGPSで距離、歩数計で歩数を計測します',
                      style: AppText.subMeta,
                    ),
                    value: _trackFitness,
                    activeColor: AppColors.sageDeep,
                    onChanged: (v) => setState(() => _trackFitness = v),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.slateDeep,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'タイマーは使わず、やらなかった日をチェックして記録します',
                          style: AppText.subMeta.copyWith(
                            color: AppColors.slateDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        final Task? task;
                        if (_isEditing) {
                          task = await service.editTask(
                            widget.editingTask!.id,
                            name: name,
                            iconIndex: _selectedIcon.index,
                            defaultMinutes: _minutes,
                            trackFitness: _mode == TaskMode.timed
                                ? _trackFitness
                                : null,
                          );
                        } else {
                          task = await service.addTask(
                            name: name,
                            iconIndex: _selectedIcon.index,
                            defaultMinutes: _minutes,
                            mode: _mode,
                            trackFitness: _trackFitness,
                          );
                        }
                        if (context.mounted) Navigator.pop(context, task);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isEditing ? '保存' : '追加'),
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

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _modeButton('続ける習慣', TaskMode.timed),
          _modeButton('やめたい習慣', TaskMode.abstain),
        ],
      ),
    );
  }

  Widget _modeButton(String label, TaskMode value) {
    final active = _mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _mode = value;
          if (value == TaskMode.abstain && _selectedIcon == TaskIconType.star) {
            _selectedIcon = TaskIconType.drink;
          }
        }),
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
