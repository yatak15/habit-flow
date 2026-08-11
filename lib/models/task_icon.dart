import 'package:flutter/material.dart';

/// タスクに割り当て可能なアイコンの定義
/// ミニマル・禅デザインに合わせたシンプルな線画系アイコンを中心に構成
/// ※ Flutter標準のMaterial Iconsのみを使用（外部アイコンパッケージへの依存を排除し、
///   SDKバージョン差異によるビルド不整合を防止）
enum TaskIconType {
  piano,
  guitar,
  zen,
  book,
  run,
  yoga,
  paint,
  language,
  code,
  music,
  dumbbell,
  pen,
  camera,
  leaf,
  star,
}

class TaskIconData {
  final TaskIconType type;
  final IconData icon;
  final String label;

  const TaskIconData({
    required this.type,
    required this.icon,
    required this.label,
  });

  static const Map<TaskIconType, TaskIconData> all = {
    TaskIconType.piano: TaskIconData(
      type: TaskIconType.piano,
      icon: Icons.piano_outlined,
      label: 'ピアノ',
    ),
    TaskIconType.guitar: TaskIconData(
      type: TaskIconType.guitar,
      icon: Icons.music_note_outlined,
      label: 'ギター',
    ),
    TaskIconType.zen: TaskIconData(
      type: TaskIconType.zen,
      icon: Icons.self_improvement_outlined,
      label: '禅・瞑想',
    ),
    TaskIconType.book: TaskIconData(
      type: TaskIconType.book,
      icon: Icons.menu_book_outlined,
      label: '読書',
    ),
    TaskIconType.run: TaskIconData(
      type: TaskIconType.run,
      icon: Icons.directions_run_outlined,
      label: 'ランニング',
    ),
    TaskIconType.yoga: TaskIconData(
      type: TaskIconType.yoga,
      icon: Icons.spa_outlined,
      label: 'ヨガ',
    ),
    TaskIconType.paint: TaskIconData(
      type: TaskIconType.paint,
      icon: Icons.palette_outlined,
      label: 'アート',
    ),
    TaskIconType.language: TaskIconData(
      type: TaskIconType.language,
      icon: Icons.language_outlined,
      label: '語学',
    ),
    TaskIconType.code: TaskIconData(
      type: TaskIconType.code,
      icon: Icons.code_outlined,
      label: 'コーディング',
    ),
    TaskIconType.music: TaskIconData(
      type: TaskIconType.music,
      icon: Icons.headphones_outlined,
      label: '音楽鑑賞',
    ),
    TaskIconType.dumbbell: TaskIconData(
      type: TaskIconType.dumbbell,
      icon: Icons.fitness_center_outlined,
      label: '筋トレ',
    ),
    TaskIconType.pen: TaskIconData(
      type: TaskIconType.pen,
      icon: Icons.edit_outlined,
      label: '執筆',
    ),
    TaskIconType.camera: TaskIconData(
      type: TaskIconType.camera,
      icon: Icons.camera_alt_outlined,
      label: '写真',
    ),
    TaskIconType.leaf: TaskIconData(
      type: TaskIconType.leaf,
      icon: Icons.eco_outlined,
      label: 'ガーデニング',
    ),
    TaskIconType.star: TaskIconData(
      type: TaskIconType.star,
      icon: Icons.star_outline,
      label: 'その他',
    ),
  };

  static TaskIconData of(TaskIconType type) => all[type]!;
}
