# Supabaseセットアップ

## この段階で実装済みのもの

- Supabase JSクライアントの読み込み
- 未設定時のIndexedDBフォールバック
- メール・パスワード認証API
- 音声BlobのStorageアップロード
- 期限付き署名URLの発行
- 鼻歌投稿API
- 募集・応募API
- 募集者だけが実行できる採用RPC
- PostgreSQLテーブル、インデックス、RLS
- ナビゲーションの `Local` / `Cloud` 表示

## 1. Supabaseプロジェクトを作る

1. https://supabase.com/dashboard を開く
2. `New project` を押す
3. Organizationを選ぶ
4. Project nameを `sonora` にする
5. Database Passwordをパスワード管理アプリへ保存する
6. Regionは利用者に近い場所を選ぶ
7. `Create new project` を押す

Database Passwordはこのリポジトリやチャットへ貼らないでください。

## 2. SQLを実行する

1. Supabase Dashboardの `SQL Editor` を開く
2. `New query` を押す
3. リポジトリの `supabase-setup.sql` をすべてコピーする
4. SQL Editorへ貼る
5. `Run` を押す

作成される主なもの:

```text
profiles
voice_posts
requests
applications
audio-private Storage bucket
adopt_application RPC
RLS policies
```

## 3. 公開接続値を取得する

Dashboardの `Project Settings → Data API` または `Connect` から次を取得します。

- Project URL
- Publishable Key

Publishable KeyはRLSと組み合わせてブラウザで使う公開値です。Service Role Keyは使いません。

## 4. サイトへ設定する

`outputs/supabase-config.js` を編集します。

```js
window.SONORA_SUPABASE_CONFIG = Object.freeze({
  url: 'https://PROJECT_REF.supabase.co',
  publishableKey: 'sb_publishable_...'
});
```

設定後にページを開き、ナビゲーションの表示が `Local` から `Cloud` へ変われば接続成功です。

## 5. Auth URLを設定する

Dashboardの `Authentication → URL Configuration` で設定します。

Site URL:

```text
https://sakana14-cyber.github.io/sonora/
```

Redirect URLs:

```text
http://localhost:5500/**
https://sakana14-cyber.github.io/sonora/**
```

## 6. 接続を確認する

UIは接続値の有無に応じて自動的に保存先を切り替えます。設定がある場合はSupabase Auth・Database・Storage、設定がない場合は従来のlocalStorage・IndexedDBを使います。

次の順に動作を確認してください。

1. ナビゲーションが `Cloud` 表示になる
2. メールアドレスと6文字以上のパスワードでアカウントを作る
3. 確認メールが有効な場合は、メール内のリンクを開いてログインする
4. 鼻歌を録音して公開し、Dashboardの `voice_posts` とStorageを確認する
5. 募集を公開し、別アカウントから音声付きで応募する

アバターを押すとCloud接続時はログアウトします。AppleログインはProvider設定をまだ行っていないため、メール・パスワード認証を使用してください。

## セキュリティ上の禁止事項

- Service Role Keyをブラウザへ入れない
- Database PasswordをGitHubへcommitしない
- AI APIやStripeのSecret Keyを `supabase-config.js` へ入れない
- RLSを無効にしない
- 採用権限を画面表示だけで制御しない
