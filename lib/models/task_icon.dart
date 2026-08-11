import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// タスクに割り当て可能なアイコンの定義
/// ミニマル・禅デザインに合わせたシンプルな線画系アイコンを中心に構成
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
      icon: FontAwesomeIcons.music,
      label: 'ピアノ',
    ),
    TaskIconType.guitar: TaskIconData(
      type: TaskIconType.guitar,
      icon: FontAwesomeIcons.guitar,
      label: 'ギター',
    ),
    TaskIconType.zen: TaskIconData(
      type: TaskIconType.zen,
      icon: FontAwesomeIcons.circleDot,
      label: '禅・瞑想',
    ),
    TaskIconType.book: TaskIconData(
      type: TaskIconType.book,
      icon: FontAwesomeIcons.bookOpen,
      label: '読書',
    ),
    TaskIconType.run: TaskIconData(
      type: TaskIconType.run,
      icon: FontAwesomeIcons.personRunning,
      label: 'ランニング',
    ),
    TaskIconType.yoga: TaskIconData(
      type: TaskIconType.yoga,
      icon: FontAwesomeIcons.spa,
      label: 'ヨガ',
    ),
    TaskIconType.paint: TaskIconData(
      type: TaskIconType.paint,
      icon: FontAwesomeIcons.palette,
      label: 'アート',
    ),
    TaskIconType.language: TaskIconData(
      type: TaskIconType.language,
      icon: FontAwesomeIcons.language,
      label: '語学',
    ),
    TaskIconType.code: TaskIconData(
      type: TaskIconType.code,
      icon: FontAwesomeIcons.code,
      label: 'コーディング',
    ),
    TaskIconType.music: TaskIconData(
      type: TaskIconType.music,
      icon: FontAwesomeIcons.headphones,
      label: '音楽鑑賞',
    ),
    TaskIconType.dumbbell: TaskIconData(
      type: TaskIconType.dumbbell,
      icon: FontAwesomeIcons.dumbbell,
      label: '筋トレ',
    ),
    TaskIconType.pen: TaskIconData(
      type: TaskIconType.pen,
      icon: FontAwesomeIcons.penNib,
      label: '執筆',
    ),
    TaskIconType.camera: TaskIconData(
      type: TaskIconType.camera,
      icon: FontAwesomeIcons.camera,
      label: '写真',
    ),
    TaskIconType.leaf: TaskIconData(
      type: TaskIconType.leaf,
      icon: FontAwesomeIcons.leaf,
      label: 'ガーデニング',
    ),
    TaskIconType.star: TaskIconData(
      type: TaskIconType.star,
      icon: FontAwesomeIcons.star,
      label: 'その他',
    ),
  };

  static TaskIconData of(TaskIconType type) => all[type]!;
}
