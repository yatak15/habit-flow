import 'package:flutter/material.dart';
import '../models/task_icon.dart';
import '../theme/app_theme.dart';

/// タスクアイコン表示用の共通ウィジェット（円形背景＋アイコン）
class TaskIconWidget extends StatelessWidget {
  final TaskIconType iconType;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const TaskIconWidget({
    super.key,
    required this.iconType,
    this.size = 44,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final data = TaskIconData.of(iconType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.sageLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        data.icon,
        size: size * 0.5,
        color: iconColor ?? AppColors.sageDark,
      ),
    );
  }
}

/// アイコン選択グリッド（新規タスク作成時に使用）
class TaskIconPicker extends StatelessWidget {
  final TaskIconType selected;
  final ValueChanged<TaskIconType> onSelected;

  const TaskIconPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: TaskIconType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onSelected(type),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.sageDark : Colors.transparent,
                width: 2,
              ),
            ),
            child: TaskIconWidget(
              iconType: type,
              size: 48,
              backgroundColor: isSelected ? AppColors.sage : AppColors.creamDark,
              iconColor: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}
