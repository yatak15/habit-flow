import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../widgets/account_section.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_flow_widgets.dart';

/// 設定画面：背景色の選択など、アプリ全体の見た目に関する設定をまとめる
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      backgroundColor: themeService.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            HFTabBar.reservedHeight(context) + 20,
          ),
          children: [
            const HeroHeader(
              eyebrow: 'SETTINGS',
              title: '設定',
              titleStyle: AppText.heroHistory,
              padding: EdgeInsets.only(top: 4, bottom: 28),
            ),
            Text('背景の色', style: AppText.h2Section),
            const SizedBox(height: 4),
            Text('お好みの背景色を選べます', style: AppText.subMeta),
            const SizedBox(height: 20),
            _buildColorPicker(context, themeService),
            const SizedBox(height: 40),
            const AccountSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, ThemeService themeService) {
    return Wrap(
      spacing: 18,
      runSpacing: 16,
      children: AppBackgroundTheme.values.map((value) {
        final selected = themeService.theme == value;
        final color = ThemeService.colorFor(value);
        return GestureDetector(
          onTap: () => themeService.setTheme(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.sageDeep : AppColors.line,
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected ? AppShadows.selectedCard : AppShadows.card,
                ),
                alignment: Alignment.center,
                child: selected
                    ? const Icon(
                        Icons.check,
                        size: 20,
                        color: AppColors.sageDeep,
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                ThemeService.labelFor(value),
                style: AppText.subMeta.copyWith(
                  fontSize: 11,
                  color: selected ? AppColors.sageDeep : AppColors.inkSub,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
