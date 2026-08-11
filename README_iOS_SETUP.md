# Habit Flow - iOS 無料枠実機ビルド手順

Apple Developer Program（年$99）に加入せず、**無料のApple ID**だけでMac実機（自分のiPhone）にインストールする手順です。

## 前提条件
- macOS + Xcode（App Storeからインストール済み）
- Flutter SDK（3.35.x系を推奨）
- 無料のApple ID（通常のiCloudログイン用IDでOK）
- iPhoneとMacをUSB接続（またはWi-Fi経由のワイヤレスデバッグ）

---

## ステップ1：リポジトリのクローン

```bash
git clone https://github.com/yatak15/habit-flow.git
cd habit-flow
flutter pub get
```

## ステップ2：CocoaPods依存解決

```bash
cd ios
pod install
cd ..
```
※ CocoaPods未導入の場合は `sudo gem install cocoapods` を先に実行してください。

## ステップ3：Xcodeでプロジェクトを開く

```bash
open ios/Runner.xcworkspace
```
⚠️ **重要**：`Runner.xcodeproj` ではなく **`Runner.xcworkspace`** を開いてください（CocoaPods利用時の必須ルール）。

## ステップ4：Signing & Capabilities の設定（無料枠の核心部分）

1. Xcode左側のプロジェクトナビゲータで **「Runner」プロジェクト** を選択
2. 中央パネルの **TARGETS → Runner** を選択
3. 上部タブから **「Signing & Capabilities」** を選択
4. **Team** のドロップダウンから、あなたの **Apple ID（Personal Team）** を選択
   - 初回はここで「Add an Account...」からApple IDでログインが必要です
   - ログイン後、自動的に「あなたの名前 (Personal Team)」が候補に表示されます
5. **Bundle Identifier** を確認（既に `com.habitflow.habitFlow` に設定済みですが、他の人が同じIDを使っていた場合は一意な値に変更が必要になることがあります。例：`com.habitflow.habitFlow.takeya`）
6. 「Automatically manage signing」にチェックが入っていることを確認

## ステップ5：iPhoneをMacに接続し、デベロッパーモードを有効化

1. iPhoneをUSBケーブルでMacに接続
2. iPhone側で「このコンピュータを信頼する」を選択
3. iPhone: **設定 → プライバシーとセキュリティ → デベロッパーモード** を **オン**にする（iOS 16以降）
4. 再起動を求められたら再起動して有効化を確定

## ステップ6：ビルド＆実機インストール

Xcode上部の実行デバイス選択で、接続したiPhoneを選択し、▶️（Run）ボタンをクリック。

またはターミナルから：
```bash
flutter devices          # 接続デバイスの確認
flutter run -d <デバイスID>
```

## ステップ7：初回起動時の「信頼されていないデベロッパ」エラー対応

初回起動時にiPhone側で以下のエラーが出る場合があります：
> 「信頼されていないデベロッパ」「未確認のApp」

対応手順：
1. iPhone: **設定 → 一般 → VPNとデバイス管理**
2. 該当のApple IDプロファイルを選択 → **「信頼」** をタップ
3. ホーム画面から「Habit Flow」アイコンを再度タップして起動

---

## ⚠️ 無料枠の制約事項（重要）

| 項目 | 内容 |
|---|---|
| **署名の有効期限** | **7日間**。期限切れ後はアプリが起動しなくなるため、Xcodeから再ビルド・再インストールが必要 |
| **同時インストール数** | 1つのApple IDで作成できるApp ID数に上限あり（複数の自作アプリを試す場合は注意） |
| **配信範囲** | 自分のiPhoneのみ。他者への配布はTestFlight/App Store（有償Developer Program）が必要 |

**運用Tips**：7日ごとにMacに接続して `flutter run` を再実行するだけで継続利用できます。日常的にMacと同期する習慣があれば負担は小さいです。

---

## トラブルシューティング

| エラー | 原因 | 対処 |
|---|---|---|
| `No profiles for 'com.habitflow.habitFlow' were found` | Bundle IDの重複、Team未設定 | Bundle IDを一意な値に変更、Teamを再選択 |
| `Untrusted Developer` | 初回起動時の標準動作 | 上記ステップ7を実施 |
| `pod install` が失敗する | CocoaPodsバージョン不整合 | `pod repo update` 後に再実行 |
| ビルド後、7日で起動しなくなる | 無料枠の署名期限 | Xcodeで再ビルド・再インストール |
