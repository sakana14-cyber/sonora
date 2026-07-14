# データとセキュリティ

## 現在の保存場所

| データ | 保存場所 | 共有範囲 |
|---|---|---|
| デモアカウント | localStorage | 同じブラウザのみ |
| 投票・投げ銭デモ | localStorage | 同じブラウザのみ |
| 鼻歌音声 | IndexedDB | 同じブラウザのみ |
| 募集・応募 | IndexedDB | 同じブラウザのみ |
| サイトのコード | GitHub | インターネット公開 |

## localStorageとIndexedDBの違い

- localStorage: 小さな文字列データ向け
- IndexedDB: Blobを含む大きな構造化データ向け

音声をlocalStorageへ保存すると容量制限や変換コストの問題があるため、IndexedDBを使用しています。

## 現在のログインについて

現在のログインはUIデモです。メールアドレスや表示名をlocalStorageへ保存しており、本人確認や安全なセッションはありません。

本番では次が必要です。

- Supabase Auth
- メール確認
- セッション管理
- パスワードをフロントエンドで保存しない設計
- ログアウト・退会・データ削除

## 本番データベース

`supabase-setup.sql` は次の関係を想定しています。

```text
auth.users
  ├─ requests.user_id
  └─ applications.user_id

requests
  └─ applications.request_id

storage.audio
  └─ ユーザーごとの音声ファイル
```

## 採用権限

募集作品を採用できるのは募集者だけです。本番では次の条件をサーバー側で検証します。

```text
ログイン中のuser_id === requests.user_id
```

画面でボタンを隠すだけでは安全ではありません。Row Level SecurityまたはサーバーAPIでも同じ条件を検証します。

## 公開してはいけないもの

次の値はGitHubへcommitしないでください。

- Supabase Service Role Key
- Stripe Secret Key
- AI生成APIのSecret Key
- データベースのパスワード
- `.env` ファイル

ブラウザで使えるPublishable Keyと秘密鍵は別物です。秘密鍵はVercelなどの環境変数へ保存し、サーバー側からのみ使用します。

## 音声サービス特有の注意

- 録音前に利用目的を説明する
- 非公開と公開を明確に分ける
- 削除機能を提供する
- AI学習への利用可否を選べるようにする
- 著作権・商用利用条件を明示する
- Content ID登録の有無を記録する

