### detection_game

```sh
# flutter のプロジェクト作成
$ flutter create .

# XCode のシミュレーション立ち上げ
- iPhone 16 Pro を選択している

# シミュレーター起動
$ open -a Simulator
# シミュレーターに実装を反映する
$ flutter run -d "iPhone 16 Pro"

# Android シミュレーターのリスト確認
$ emulator -list-avds
# Android シミュレーター起動
$ emulator -avd Pixel_9

# Android シミュレーターのID確認
$ flutter devices

$ flutter pub get

# Android スマホでflutter立ち上げ
$ flutter run -d emulator-5554 --dart-define=VISION_API_KEY=YOUR_API_KEY
```

### フェーズ1 PoC（Issue #10）: 実装概要
- VisionService 抽象化と ClientDirectVisionAdapter（Google Cloud Vision 直叩き・PoC用途）
- 画像圧縮（JPEG、長辺最大1280px、品質85）
- UI: 撮影 → 解析 → バウンディングボックスとラベル名表示（スコア非表示）
- ギャラリー保存機能: gallery_saver_plus 3.2.9

### 環境変数の設定（ローカル専用キー）
- GCP Vision API キーは配布不可。`.env`はコミットしない
- 実行時に `--dart-define` で注入する

```sh
# 例: 実行コマンド（iOS/Androidいずれも）
$ flutter run --dart-define=VISION_API_KEY=xxxx_your_local_key_xxxx

# ビルド例
$ flutter build apk --debug --dart-define=VISION_API_KEY=xxxx_your_local_key_xxxx
```

- `.env.example` を参考にしてください（中身は空のプレースホルダ）

### iOS の権限
- フォトライブラリ保存のため Info.plist に以下キーを追加済み
  - NSPhotoLibraryAddUsageDescription
  - NSPhotoLibraryUsageDescription

### 参考サイト
- [Take a picture using the camera](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)
