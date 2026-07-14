# Sonora

鼻歌やボイスメモから欲しい音を伝え、AIの見本と人間のクリエイターによって効果音・BGMを完成させるWebサービスのプロトタイプです。

- 公開サイト: https://sakana14-cyber.github.io/sonora/
- 技術構成: HTML / CSS / JavaScript / Web Audio API / IndexedDB / GitHub Actions
- 現在の段階: フロントエンド・プロトタイプ

## まず理解してほしいこと

このプロジェクトには、現在2種類の処理があります。

1. **実際にブラウザで動く処理**
   - マイク録音
   - 音量に反応するアニメーション
   - Web Audio APIによる効果音・BGM合成
   - 再生プレイヤー
   - IndexedDBへのローカル保存
   - 投票やフィルターなどのUI操作

2. **本番サービスを想定したデモ処理**
   - AIによる本格的な音声生成
   - 全ユーザーで共有される投稿
   - 本物のログイン
   - 決済・投げ銭
   - YouTubeでの使用追跡

デモ処理はUIと操作の流れを確認するためのものです。本番化にはSupabase、AI音声API、Stripeなどを接続します。

## ファイル構成

```text
sonora/
├─ README.md                     # このプロジェクトの入口
├─ docs/
│  ├─ ARCHITECTURE.md            # ファイル同士と処理のつながり
│  ├─ CODE_WALKTHROUGH.md        # 主要関数を読む順番
│  ├─ DATA_AND_SECURITY.md       # 保存データとセキュリティ
│  ├─ DEPLOYMENT.md              # GitHub Pagesの公開手順
│  └─ SUPABASE_SETUP.md          # Supabaseの作成・接続手順
├─ outputs/
│  ├─ index.html                 # 基本画面、録音、音声、DB、プレイヤー
│  ├─ innovation.css             # Creative Network機能の見た目
│  ├─ innovation.js              # バトル、DNA、動画解析デモなど
│  ├─ supabase-config.js         # 公開可能なSupabase接続値
│  ├─ supabase-client.js         # Auth・DB・Storage通信
│  └─ .nojekyll                  # GitHub Pagesへそのまま配信する設定
├─ supabase-setup.sql            # 本番DB・Storage・権限の設計案
├─ .github/workflows/
│  └─ deploy-pages.yml           # mainへのpushで自動公開
└─ .vscode/                      # VS CodeとLive Serverの設定
```

詳しい関係図は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) を参照してください。

## おすすめの学習順序

1. このREADMEで全体像を理解する
2. [ARCHITECTURE.md](docs/ARCHITECTURE.md) で処理の流れを見る
3. `outputs/index.html` のHTML部分で画面構成を見る
4. `outputs/index.html` の `record()` でマイク録音を学ぶ
5. `playEffectPreset()` と `playMachine()` でWeb Audio APIを学ぶ
6. `dbReady` と `dbTransaction()` でIndexedDBを学ぶ
7. `outputs/innovation.js` で機能を追加する方法を学ぶ
8. `deploy-pages.yml` で自動公開の仕組みを学ぶ

関数ごとの役割は [docs/CODE_WALKTHROUGH.md](docs/CODE_WALKTHROUGH.md) にまとめています。

## ローカルで動かす

マイク録音には `https://` または `localhost` が必要です。HTMLファイルを直接ダブルクリックするのではなく、Live Serverを使用してください。

1. VS Codeでこのフォルダを開く
2. 推奨拡張機能 **Live Server** をインストール
3. `outputs/index.html` を開く
4. 右下の **Go Live** を押す
5. `http://localhost:5500/outputs/` を開く

## よく変更する場所

| 変更したい内容 | 主に編集する場所 |
|---|---|
| ページ内の文章 | `outputs/index.html` の `<main>` |
| 基本画面の色・余白 | `outputs/index.html` の `<style>` |
| 新機能エリアの見た目 | `outputs/innovation.css` |
| 効果音の音色 | `scheduleEffect()` |
| BGMの進行 | `pulseSynth()` |
| 録音処理 | `record()` / `startMeter()` |
| 再生バー | `playMediaItem()` / `setPlayingState()` |
| 投稿・募集の保存 | `dbTransaction()` |
| Creative Network | `outputs/innovation.js` |
| 本番DB設計 | `supabase-setup.sql` |
| 公開処理 | `.github/workflows/deploy-pages.yml` |

## GitHub Pagesへの公開

`main` ブランチへpushすると、GitHub Actionsが `outputs/` を公開します。

```text
git add .
git commit -m "変更内容"
git push origin main
```

詳細は [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) を参照してください。

## 次に本番化する部分

1. Supabase Authで本物のログインを実装
2. Supabase Storageへ音声を保存
3. IndexedDBからPostgreSQLへ募集・応募を移行
4. 効果音・BGM生成APIをサーバー経由で接続
5. Stripe Connectで依頼料と報酬を処理
6. テスト・監視・利用規約を整備

保存データと権限については [docs/DATA_AND_SECURITY.md](docs/DATA_AND_SECURITY.md) を確認してください。

Supabaseを接続するときは [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) の順番で進めてください。
