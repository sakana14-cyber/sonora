# コード読解ガイド

## `outputs/index.html` の読み方

ファイルは上から次の順番です。

1. `<head>`: 文字コード、フォント、外部CSS・JS
2. `<style>`: 基本画面、録音、一覧、モーダル、プレイヤー
3. `<body>`: ナビゲーションと基本セクション
4. モーダル: ログイン・募集フォーム
5. `<script>`: 動作を担当するJavaScript

## 録音機能

| 関数 | 役割 |
|---|---|
| `record()` | マイクの開始・停止とMediaRecorderの制御 |
| `startMeter()` | AnalyserNodeから音量を取得してバーを動かす |
| `stopMeter()` | 音量アニメーションとAudioContextを終了 |
| `setCapturedAudio()` | 録音Blobを試聴・投稿可能な状態にする |

学習ポイント:

- `navigator.mediaDevices.getUserMedia()`
- `MediaRecorder`
- `Blob`
- `URL.createObjectURL()`
- `requestAnimationFrame()`

## 音声合成

| 関数 | 役割 |
|---|---|
| `synthTone()` | OscillatorとGainで一つの音を鳴らす |
| `effectNoise()` | ノイズへフィルターを適用する |
| `scheduleEffect()` | プリセット別に複数レイヤーを組み合わせる |
| `playEffectPreset()` | 効果音を共通プレイヤーで開始する |
| `synthDrum()` | BGM用キックとハイハットを作る |
| `pulseSynth()` | BGMのコード・ベース・旋律を進行させる |
| `playMachine()` | BGM合成を開始する |

音色を変更するときは、まず `scheduleEffect()` の一つのプリセットだけを変更して比較してください。

## 共通プレイヤー

| 関数 | 役割 |
|---|---|
| `capturePlayTrigger()` | どの再生ボタンから始まったか記録 |
| `setPlayingState()` | 再生ボタンとプレイヤーの表示を同期 |
| `stopCurrentPlayback()` | 現在の音源とタイマーを停止 |
| `playMediaItem()` | Blobや音声URLを再生 |
| `updatePlayerProgress()` | 時間とシークバーを更新 |

同じボタンをもう一度押して止める処理は `capturePlayTrigger()` が担当します。

## IndexedDB

データベース名は `sonoraDB` です。

| オブジェクトストア | 保存内容 |
|---|---|
| `voicePosts` | 鼻歌投稿と音声Blob |
| `requestPosts` | 効果音・BGMの募集 |
| `applications` | 募集への応募と制作サンプル |

| 関数 | 役割 |
|---|---|
| `dbReady` | DBを開き、必要ならテーブルを作る |
| `dbTransaction()` | 読み書き処理をPromiseとして扱う |
| `loadVoicePosts()` | 鼻歌投稿を一覧へ反映 |
| `loadRequestJobs()` | 募集中データをカードへ反映 |
| `publishVoicePost()` | 録音BlobをDBへ保存 |

IndexedDBは同じブラウザ内だけで共有されます。本番ではSupabaseへ置き換えます。

## `outputs/innovation.js` の読み方

このファイルは即時関数で囲み、変数がグローバルへ漏れないようにしています。

```js
(() => {
  // この中だけで使う状態と関数
})();
```

主要関数:

| 関数 | 役割 |
|---|---|
| `markup()` | Creative NetworkのHTMLを組み立てる |
| `renderWanted()` | 期限付き募集を描画 |
| `openLicense()` | Sound Passportを表示 |
| `generatePack()` | YouTuber用効果音パックを生成 |
| `buildTimeline()` | 動画タイムラインのデモを作る |
| `updateDNA()` | スライダーから音の特徴を決める |
| `createShareClip()` | Canvasから短いWebM動画を作る |
| `bind()` | ボタンと関数を接続する |
| `init()` | 追加機能全体を起動する |

## 変更の基本ルール

1. 画面だけの変更はCSSから始める
2. 既存の音声関数を再利用する
3. ユーザー入力をHTMLへ入れる場合は必ずエスケープする
4. 音声BlobはlocalStorageへ入れない
5. 新しいDB処理は `dbTransaction()` を通す
6. 変更後はローカル確認してからcommitする

