# ローカルPoC (C案: クライアント直Vision)

- 本PoCは開発者ローカル限定で使用してください（鍵は配布禁止）
- 実行例:
```
flutter pub get
flutter run --dart-define=VISION_API_KEY=YOUR_API_KEY
```


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
# Android スマホでflutter立ち上げ
$ flutter run -d emulator-5554
```

### 参考サイト
- [Take a picture using the camera](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)
