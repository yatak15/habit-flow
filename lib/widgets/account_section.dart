import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

/// 設定画面のアカウント欄：ログイン／新規登録／同期状況の表示
class AccountSection extends StatefulWidget {
  const AccountSection({super.key});

  @override
  State<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<AccountSection> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(SyncService sync, {required bool signUp}) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() {
        _message = 'メールアドレスと、6文字以上のパスワードを入力してください。';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final error = signUp
        ? await sync.signUp(email, password)
        : await sync.signIn(email, password);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = error;
      _messageIsError = !(signUp && error != null && error.contains('確認メール'));
      if (error == null) _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('アカウントと同期', style: AppText.h2Section),
        const SizedBox(height: 4),
        Text('iPhone・Macなど複数の端末で習慣の記録を共有できます', style: AppText.subMeta),
        const SizedBox(height: 16),
        if (!sync.isConfigured)
          _card(
            child: Text(
              '同期はまだ設定されていません。lib/config/supabase_config.dart に '
              'Supabase の接続情報を入力すると、ログインできるようになります。',
              style: AppText.subMeta,
            ),
          )
        else if (sync.isSignedIn)
          _signedIn(sync)
        else
          _signedOut(sync),
      ],
    );
  }

  Widget _signedIn(SyncService sync) {
    final last = sync.lastSyncedAt;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sync.email ?? '', style: AppText.rowLabel),
          const SizedBox(height: 6),
          Text(
            sync.isSyncing
                ? '同期中…'
                : last == null
                ? 'まだ同期していません'
                : '最終同期 ${_fmt(last)}',
            style: AppText.subMeta,
          ),
          if (sync.lastError != null) ...[
            const SizedBox(height: 6),
            Text(
              sync.lastError!,
              style: AppText.subMeta.copyWith(color: AppColors.terracotta),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: sync.isSyncing ? null : sync.sync,
                  style: _filled,
                  child: const Text('今すぐ同期'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: sync.isSyncing ? null : sync.signOut,
                  style: _outlined,
                  child: const Text('ログアウト'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signedOut(SyncService sync) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: _decoration('メールアドレス'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: _decoration('パスワード（6文字以上）'),
            onSubmitted: (_) => _submit(sync, signUp: false),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: AppText.subMeta.copyWith(
                color: _messageIsError
                    ? AppColors.terracotta
                    : AppColors.sageDeep,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _submit(sync, signUp: false),
                  style: _filled,
                  child: const Text('ログイン'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _submit(sync, signUp: true),
                  style: _outlined,
                  child: const Text('新規登録'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: child,
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.bg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.line),
    ),
  );

  ButtonStyle get _filled => FilledButton.styleFrom(
    backgroundColor: AppColors.sageDeep,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  ButtonStyle get _outlined => OutlinedButton.styleFrom(
    foregroundColor: AppColors.sageDeep,
    side: const BorderSide(color: AppColors.sageDeep),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  String _fmt(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
