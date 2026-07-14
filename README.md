# sonora site

世界中の参加者が鼻歌・ボイスメモから機械音を共同制作する、静的フロントエンドのプロトタイプです。

## VS Code で始める

1. VS Code でこのフォルダを開きます。
2. 推奨拡張機能 **Live Server** をインストールします。
3. `outputs/index.html` を開き、右下の **Go Live** を押します。

ブラウザで `http://localhost:5500` を開くと、マイク録音を含む機能をローカル環境で試せます。

## 編集する場所

- `outputs/index.html` — サイトの HTML / CSS / JavaScript
- `.vscode/` — VS Code のプレビュー設定

## 現在の機能

- 鼻歌やボイスメモの録音／音声ファイル選択
- 効果音・BGMモードの切り替え
- Web Audio API を使った機械音プレビュー
- 効果音無料／BGM価格設定のマーケットUI

実際の AI 変換、ユーザー登録、決済、音源保存はバックエンド連携が必要です。この版では、それらの体験フローとフロントエンドの見た目を実装しています。

## インターネット公開

`.github/workflows/deploy-pages.yml` は、`main` ブランチの `outputs` フォルダをGitHub Pagesへ公開します。GitHubリポジトリの Settings → Pages で、Sourceを **GitHub Actions** に設定してください。

全ユーザーで募集・応募・音声を共有するにはSupabase接続が必要です。`supabase-setup.sql` をSupabaseのSQL Editorで実行すると、募集・応募テーブル、音声バケット、基本的なRLSポリシーを作成できます。プロジェクトURLと公開用キーをフロントエンドへ設定するまでは、データは従来どおりブラウザ内のIndexedDBへ保存されます。
