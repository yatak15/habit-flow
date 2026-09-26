/// Supabase プロジェクトの接続情報。
/// Supabase ダッシュボード > Project Settings > API の
/// 「Project URL」と「Publishable key（anon public でも可）」を貼り付けてください（anon キーは公開して問題ないキーです）。
/// 空のままの場合、同期機能は無効になり、これまで通り端末内だけで動作します。
class SupabaseConfig {
  static const String url = 'https://hsxudwqtkvohkvspbrat.supabase.co';
  static const String anonKey = 'sb_publishable_yZRDulF-D_SnhgbW-J9yZQ_b05D7uJG';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
