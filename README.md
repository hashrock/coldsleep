# Coldsleep

macOS メニューバー常駐の録音 & 書き起こしアプリ。

録音を停止すると、音声ファイル (.m4a) を保存し、macOS のオンデバイス音声認識で自動的にテキスト (.txt) に書き起こします。

## 機能

- メニューバーからワンクリックで録音開始 / 停止
- 録音終了後、自動で日本語書き起こし (オフライン対応)
- 保存先フォルダをメニューから変更可能
- 通知で録音完了・書き起こし完了をお知らせ

## ビルド

```sh
./build.sh
```

`Coldsleep.app` が生成されます。

## インストール

```sh
cp -r Coldsleep.app /Applications/
```

## 使い方

```sh
open Coldsleep.app
```

メニューバーのアイコンをクリック → **録音開始** で録音、もう一度クリック → **録音停止** で保存 & 書き起こし。

### 保存先

デフォルト: `~/Dropbox/Recordings/`

メニューの「保存先を変更...」またはコマンドで変更:

```sh
defaults write com.hashrock.coldsleep savePath ~/Desktop/Recordings
```

### 出力ファイル

```
~/Dropbox/Recordings/
  2026-03-22_23-15-30.m4a   # 音声
  2026-03-22_23-15-30.txt   # 書き起こし
```

## 必要な権限

初回起動時にダイアログが表示されます:

- **マイク** - 録音に使用
- **音声認識** - 書き起こしに使用

## 動作環境

- macOS 13 (Ventura) 以降
- Swift 5.9+
