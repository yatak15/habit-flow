import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリ背景として選べる5色
enum AppBackgroundTheme { ivory, sage, sand, sky, blush }

/// 背景色の選択・永続化を担うサービス
class ThemeService extends ChangeNotifier {
  static const _prefKey = 'app_background_theme';

  AppBackgroundTheme _theme = AppBackgroundTheme.ivory;

  AppBackgroundTheme get theme => _theme;
  Color get backgroundColor => colorFor(_theme);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefKey);
    if (idx != null && idx >= 0 && idx < AppBackgroundTheme.values.length) {
      _theme = AppBackgroundTheme.values[idx];
    }
  }

  Future<void> setTheme(AppBackgroundTheme value) async {
    if (_theme == value) return;
    _theme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, value.index);
  }

  static Color colorFor(AppBackgroundTheme theme) {
    switch (theme) {
      case AppBackgroundTheme.ivory:
        return const Color(0xFFF6F3EC);
      case AppBackgroundTheme.sage:
        return const Color(0xFFEDF3E7);
      case AppBackgroundTheme.sand:
        return const Color(0xFFF6ECDE);
      case AppBackgroundTheme.sky:
        return const Color(0xFFE9F0F4);
      case AppBackgroundTheme.blush:
        return const Color(0xFFF7EAE8);
    }
  }

  static String labelFor(AppBackgroundTheme theme) {
    switch (theme) {
      case AppBackgroundTheme.ivory:
        return 'アイボリー';
      case AppBackgroundTheme.sage:
        return 'セージ';
      case AppBackgroundTheme.sand:
        return 'サンド';
      case AppBackgroundTheme.sky:
        return 'スカイ';
      case AppBackgroundTheme.blush:
        return 'ブラッシュ';
    }
  }
}
