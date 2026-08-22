import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/task_icon.dart';
import '../theme/app_theme.dart';

/// "Quiet Momentum" デザインシステム共通コンポーネント群

/// ホーム画面上部の週次サマリー（3列・仕切り線）
class MomentumStrip extends StatelessWidget {
  final int weeklyCount;
  final int longestStreak;
  final int? daysToNextPrize;

  const MomentumStrip({
    super.key,
    required this.weeklyCount,
    required this.longestStreak,
    this.daysToNextPrize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MomentumItem(
              label: '今週の実行',
              value: '$weeklyCount',
              suffix: '回',
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          const SizedBox(width: 12),
          Expanded(
            child: _MomentumItem(
              label: '最長継続',
              value: '$longestStreak',
              suffix: '日',
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.line),
          const SizedBox(width: 12),
          Expanded(
            child: _MomentumItem(
              label: '次のプライズ',
              value: daysToNextPrize != null ? '$daysToNextPrize' : '—',
              suffix: daysToNextPrize != null ? '日' : '',
              valueColor: AppColors.terracotta,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentumItem extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color? valueColor;

  const _MomentumItem({
    required this.label,
    required this.value,
    required this.suffix,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.subMeta.copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppText.momentumValue.copyWith(
              color: valueColor ?? AppColors.ink,
            ),
            children: [
              TextSpan(text: value),
              if (suffix.isNotEmpty)
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkSub,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// タスクカード（本日のタスク一覧・選択済みカルーセル共通）
class TaskCardWidget extends StatelessWidget {
  final TaskIconType icon;
  final String label;
  final int streak;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const TaskCardWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.streak,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double h = compact ? 108 : 132;
    final double w = compact ? 108 : 132;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: w,
        height: h,
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageDeep : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: selected ? null : Border.all(color: AppColors.line),
          boxShadow: selected ? AppShadows.selectedCard : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.sageBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                TaskIconData.of(icon).icon,
                size: 20,
                color: selected ? Colors.white : AppColors.sageDeep,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardLabel.copyWith(
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                ),
                if (streak > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : AppColors.sage,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak日継続',
                        style: AppText.streakCaption.copyWith(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.75)
                              : AppColors.inkSub,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// タスク追加カード（点線ボーダー）
class AddTaskCardWidget extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;

  const AddTaskCardWidget({
    super.key,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 108 : 132;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(radius: 22, color: AppColors.line),
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: AppColors.inkMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                '追加',
                style: AppText.subMeta.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final double radius;
  final Color color;
  _DashedBorderPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashArray: [6, 5]);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source, {required List<double> dashArray}) {
    final Path dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      int i = 0;
      while (distance < metric.length) {
        final len = dashArray[i % dashArray.length];
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
        i++;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 継続日数・実行回数・プライズを示すチップ
class StreakChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;

  const StreakChip({
    super.key,
    required this.icon,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accent ? AppColors.terraSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? AppColors.terraSoft : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: accent ? AppColors.terracotta : AppColors.sageDeep,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.chipLabel.copyWith(
              color: accent ? AppColors.terracotta : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// 次のプライズまでの進捗メーター（グラデーション）
class ProgressMeter extends StatelessWidget {
  final double progress; // 0.0〜1.0
  final int daysRemaining;
  final String nextPrizeTitle;

  const ProgressMeter({
    super.key,
    required this.progress,
    required this.daysRemaining,
    required this.nextPrizeTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('次のプライズまで', style: AppText.subMeta),
            RichText(
              text: TextSpan(
                style: AppText.subMeta.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  const TextSpan(text: 'あと '),
                  TextSpan(
                    text: '$daysRemaining日',
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(text: ' ・ $nextPrizeTitle'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 6,
            color: AppColors.line,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sage, AppColors.terracotta],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// メインCTAボタン（高さ64・角丸20・セージ影）
class PrimaryCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const PrimaryCta({
    super.key,
    required this.label,
    this.icon = Icons.play_arrow,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.cta,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: Colors.white),
          label: Text(label, style: AppText.ctaLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sageDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

/// カスタムタブバー（半透明＋ブラー）
class HFTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HFTabBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.bg.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tabItem(icon: Icons.home_rounded, label: 'ホーム', index: 0),
              _tabItem(icon: Icons.bar_chart_rounded, label: '履歴', index: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: active ? AppColors.sageDeep : AppColors.inkMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.sageDeep : AppColors.inkMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eyebrow（日付ラベル）+ Hero Title 共通ヘッダー
class HeroHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final TextStyle? titleStyle;
  final EdgeInsets padding;

  const HeroHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleStyle,
    this.padding = const EdgeInsets.only(top: 12, bottom: 32),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: AppText.eyebrow),
          const SizedBox(height: 8),
          Text(title, style: titleStyle ?? AppText.heroHome),
        ],
      ),
    );
  }
}

/// タイマースライダー用スライダーテーマ（白サム＋セージ縁取り）
SliderThemeData hfSliderTheme() {
  return SliderThemeData(
    trackHeight: 6,
    activeTrackColor: AppColors.sageDeep,
    inactiveTrackColor: AppColors.line,
    thumbShape: const _HFThumbShape(),
    overlayShape: SliderComponentShape.noOverlay,
    valueIndicatorColor: AppColors.sageDeep,
  );
}

class _HFThumbShape extends SliderComponentShape {
  const _HFThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 28);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = const Color(0x261F221E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(0, 2), 14, shadowPaint);

    final fillPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 14, fillPaint);

    final borderPaint = Paint()
      ..color = AppColors.sageDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 13, borderPaint);
  }
}

/// プロンプト（ヒント）カード：ホーム画面デフォルト状態で表示
class PromptCard extends StatelessWidget {
  final String title;
  final String body;

  const PromptCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.sageBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.sageDeep,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardLabel.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: AppText.subMeta.copyWith(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
