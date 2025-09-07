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
$ flutter run -d emulator-5554 --dart-define=VISION_API_KEY=YOUR_API_KEY --flavor debug

# Android apk ビルド
$ flutter build apk --release

# Android appbundle ビルド
$ flutter build appbundle --release

$ flutter build appbundle --release --verbose
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

### 注意点

- API キーをクライアントへ返すのは本番では推奨されません。今回は検証用です。本番では Functions 側から目的の外部 API を代理実行して、必要な結果のみ返す構成にしましょう。
- App Check は本番で必須です。動作確認が終わったら、Flutter 側に firebase_app_check を導入して有効化し、Functions の enforceAppCheck: true を戻してください。導入手順の実装もお手伝いできます。


### 参考サイト
- [Take a picture using the camera](https://docs.flutter.dev/cookbook/plugins/picture-using-came

- [flutter にFirebaseを追加する](https://firebase.google.com/docs/flutter/setup?hl=ja&platform=ios)

- [Firebase Distribution でテスターにアプリ配布](https://firebase.google.com/docs/app-distribution/android/distribute-console?hl=ja&_gl=1*1yfpyy*_up*MQ..*_ga*ODAwMjA1NTQzLjE3NTY5OTI3MTg.*_ga_CW55HF8NVT*czE3NTY5OTI3MTgkbzEkZzAkdDE3NTY5OTI3MTgkajYwJGwwJGgw)

- [Secret Manager で環境変数を管理する](https://firebase.google.com/docs/functions/config-env?hl=ja&gen=2nd)

- [Flutter アプリで App Check を使ってみる](https://firebase.google.com/docs/app-check/flutter/default-providers?hl=ja)

- [Google Play を Firebase にリンクする](https://support.google.com/firebase/answer/6392038)

```sh
# 機密情報の環境変数を cloud functions に設定する
$ firebase functions:secrets:set VISION_API_KEY --project your-project-id

# GCP Secret Manager API を有効にする
# App Engine Admin API を有効にする
- .firebaserc のプロジェクトIDを変更する
- google-services.json を更新する

# cloud functions にデプロイする
$ firebase deploy --only functions --project your-project-id
```

- [証明書の Keytool](https://developers.google.com/android/guides/client-auth?hl=ja)
```sh
# デバッグ用証明書のフィンガープリントを取得する
$ keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore

# キーストアがあるか確認
$ keytool -list -v -keystore ../../.android/upload-keystore.jks -alias upload
```

### Firebase の設定

- debug用の証明書のフィンガープリントを取得
  - [クライアント認証](https://developers.google.com/android/guides/client-auth?hl=ja#keytool-certificate)
```sh
$ keytool -list -v \
-alias androiddebugkey -keystore ~/.android/debug.keystore
```

### リリース用の設定を行う

- リリース用のアップロードキーストアを作成
- [Create an upload keystore](https://docs.flutter.dev/deployment/android#create-an-upload-keystore)
```sh
$ keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA \
        -keysize 2048 -validity 10000 -alias upload
```

- リリース用証明書のフィンガープリントを取得

```sh
$ keytool -list -v \
-alias upload -keystore ~/.android/upload-keystore.jks
```

```sh
$ touch android/key.properties
```
- key.properties に下記を入力
```sh
storeFile=../../../../.android/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

- [android/app/build.gradle.kts を修正](https://github.com/KJMAN678/detection_game/issues/19#issue-3389314083)

### Google Play Console
- [Google Play Console](https://play.google.com/console)

```sh
# Android appbundle ビルド
$ flutter build appbundle --release

# ログを詳細に出力するビルド
$ flutter build appbundle --release --verbose
```
