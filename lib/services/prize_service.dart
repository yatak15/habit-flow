import 'package:flutter/material.dart';

/// 継続日数に応じたプライズ（バッジ）の定義
/// STP戦略：継続率向上のためのマイルストーン設計
class Prize {
  final int requiredDays;
  final String title;
  final IconData icon;

  const Prize({required this.requiredDays, required this.title, required this.icon});
}

class PrizeService {
  static const List<Prize> milestones = [
    Prize(requiredDays: 3, title: '3日継続', icon: Icons.spa_outlined),
    Prize(requiredDays: 7, title: '1週間継続', icon: Icons.local_florist_outlined),
    Prize(requiredDays: 14, title: '2週間継続', icon: Icons.eco_outlined),
    Prize(requiredDays: 30, title: '1ヶ月継続', icon: Icons.emoji_events_outlined),
    Prize(requiredDays: 100, title: '100日継続', icon: Icons.workspace_premium_outlined),
    Prize(requiredDays: 365, title: '1年継続', icon: Icons.auto_awesome_outlined),
  ];

  /// 現在の継続日数で獲得済みの最高プライズ
  static Prize? currentPrize(int streak) {
    Prize? result;
    for (final m in milestones) {
      if (streak >= m.requiredDays) {
        result = m;
      }
    }
    return result;
  }

  /// 次に目指すプライズ
  static Prize? nextPrize(int streak) {
    for (final m in milestones) {
      if (streak < m.requiredDays) {
        return m;
      }
    }
    return null;
  }

  /// 今回の完了でちょうどマイルストーンに到達したか
  static Prize? justAchieved(int streak) {
    for (final m in milestones) {
      if (streak == m.requiredDays) {
        return m;
      }
    }
    return null;
  }
}
