import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase プロジェクトの接続情報。
/// Firebase コンソール > プロジェクトの設定 > マイアプリ で、各プラットフォームのアプリを登録し、
/// 表示される apiKey・appId・messagingSenderId・projectId を貼り付けてください（公開して問題ない値です）。
/// 空のままのプラットフォームでは同期機能は無効になり、これまで通り端末内だけで動作します。
class FirebaseConfig {
  static const String projectId = '';
  static const String messagingSenderId = '';

  // iPhone（バンドルID: com.takeyasuny.habitflow）
  static const String iosApiKey = '';
  static const String iosAppId = '';

  // Mac（バンドルID: com.habitflow.habitFlow）
  static const String macosApiKey = '';
  static const String macosAppId = '';

  // Android（パッケージ名: com.habitflow.habit_flow）
  static const String androidApiKey = '';
  static const String androidAppId = '';

  /// 実行中のプラットフォーム用の接続情報。未設定・非対応の場合は null
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb || projectId.isEmpty || messagingSenderId.isEmpty) return null;
    final (apiKey, appId) = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => (iosApiKey, iosAppId),
      TargetPlatform.macOS => (macosApiKey, macosAppId),
      TargetPlatform.android => (androidApiKey, androidAppId),
      _ => ('', ''),
    };
    if (apiKey.isEmpty || appId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      iosBundleId: switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'com.takeyasuny.habitflow',
        TargetPlatform.macOS => 'com.habitflow.habitFlow',
        _ => null,
      },
    );
  }

  static bool get isConfigured => currentPlatform != null;
}
