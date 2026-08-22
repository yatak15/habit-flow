import 'package:flutter/material.dart';
import '../models/task_icon.dart';
import '../theme/app_theme.dart';

/// タスクアイコン表示用の共通ウィジェット（角丸スクエア背景＋アイコン）
/// "Quiet Momentum" デザイン：icon slot は radius 12（小）/ 16（中）の角丸スクエア
class TaskIconWidget extends StatelessWidget {
  final TaskIconType iconType;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double radius;

  const TaskIconWidget({
    super.key,
    required this.iconType,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final data = TaskIconData.of(iconType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.sageBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(
        data.icon,
        size: size * 0.5,
        color: iconColor ?? AppColors.sageDeep,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.sageDeep : Colors.transparent,
                width: 2,
              ),
            ),
            child: TaskIconWidget(
              iconType: type,
              size: 48,
              radius: 14,
              backgroundColor: isSelected
                  ? AppColors.sageDeep
                  : AppColors.sageBg,
              iconColor: isSelected ? Colors.white : AppColors.sageDeep,
            ),
          ),
        );
      }).toList(),
    );
  }
}
