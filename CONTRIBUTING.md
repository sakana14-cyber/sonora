# Sonoraへ変更を加える方法

## 変更前

1. `git status` で未保存の変更を確認する
2. Live Serverで公開前のサイトを開く
3. 変更する機能を一つに絞る

## 変更の種類と確認項目

### 見た目

- PCとスマートフォンの両方で確認
- ボタンや文字がカードからはみ出していないか
- `:focus-visible` が残っているか
- `prefers-reduced-motion` を壊していないか

### 音声

- 同じ再生ボタンを2回押すと停止するか
- 別の音を再生したとき前の音が停止するか
- 下部プレイヤーとボタン表示が同期するか
- AudioContextとタイマーが終了しているか

### データ

- 音声BlobをlocalStorageへ入れていないか
- IndexedDBのバージョン変更が必要か
- ユーザー入力をHTMLエスケープしているか
- 募集者だけが採用できる設計になっているか

## コミット

```bash
git add .
git diff --cached --check
git commit -m "変更内容"
git push origin main
```

コミットメッセージは「何をしたか」が分かる短い文章にします。

例:

```text
Improve mobile player layout
Add license information to requests
Document IndexedDB stores
```

## 公開後

1. GitHub Actionsが成功したか確認
2. https://sakana14-cyber.github.io/sonora/ を開く
3. キャッシュが残る場合は強制再読み込み
4. 録音・再生・募集の主要操作を確認

