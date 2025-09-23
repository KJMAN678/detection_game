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

# Android apk ビルド for Firebase App Distribution
$ flutter build apk --debug

# cloud functions にデプロイする
$ firebase deploy --only functions --project your-project-id

# Android appbundle ビルド
$ flutter build appbundle --release

$ flutter build appbundle --release --verbose
```

### 環境変数の設定（ローカル専用キー）
- GCP Vision API キーは配布不可。`.env`はコミットしない
- 実行時に `--dart-define` で注入する

```sh
# 例: 実行コマンド（iOS/Androidいずれも）
$ flutter run --dart-define=VISION_API_KEY=xxxx_your_local_key_xxxx

# ビルド例
$ flutter build apk --debug --dart-define=VISION_API_KEY=xxxx_your_local_key_xxxx
```

### Firebase の利用

```sh
# 機密情報の環境変数を cloud functions に設定する
$ firebase functions:secrets:set VISION_API_KEY --project your-project-id

# GCP Secret Manager API を有効にする
# App Engine Admin API を有効にする
# Firebase が利用しているサービスアカウントに、Secret Manager のアクセス献言を付与する
- 下記コマンドで、サービスアカウントのメールアドレスを確認できる
$ gcloud functions describe analyzeImage \
  --region=us-central1 --gen2 \
  --format='value(serviceConfig.serviceAccountEmail)'

- .firebaserc のプロジェクトIDを変更する
- google-services.json を更新する

# cloud functions にデプロイする
# 関数名を analyzeImage としている
$ firebase deploy --only functions:analyzeImage --project your-project-id

- なお、関数が実際にデプロイされているかは、下記コマンドを実施すればわかる
$ firebase functions:list --project your-project-id
```

- [証明書の Keytool](https://developers.google.com/android/guides/client-auth?hl=ja)
```sh
# デバッグ用証明書のフィンガープリントを取得する
$ keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore

# キーストアがあるか確認
$ keytool -list -v -keystore ../../.android/upload-keystore.jks -alias upload
```

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
- password は key.properties に記載されている
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

#### Firebase TestLab
```sh
# Firebase TestLab
$ gcloud components update
$ gcloud auth login
$ gccloud config set project FIREBASE_PROJECT_ID

# 利用可能なデバイスを確認
$ gcloud firebase test android models list

#  特定の Android MODEL_ID に関する詳細情報を取得します。tokay は Pixel 9
$ gcloud firebase test android models describe tokay

# テストに利用可能な OS のバージョンを確認
$ gcloud firebase test android versions list

# テストに利用可能なロケールを確認
$ gcloud firebase test android locales list 

# テストを実行するためのコマンドライン オプションをすべて表示できる
$ gcloud help firebase test android run

# Robo テスト用に apk を生成
$ flutter build apk --release

# Robo テストを実行
# clients-details は、Firebase コンソールでテスト マトリックスを見つけやすくするために、テスト マトリックスにラベルを付ける
$ gcloud firebase test android run \
  --type robo \
  --app build/app/outputs/flutter-apk/app-release.apk  \
  --device model=tokay,version=36,locale=ja,orientation=portrait \
  --device model=tokay,version=36,locale=ja,orientation=landscape \
  --timeout 90s \
  --client-details matrixLabel="Example matrix label"
```
- [ユニットテスト])(https://docs.flutter.dev/cookbook/testing/unit/introduction)
- [ウィジェットテスト](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [統合テスト](https://docs.flutter.dev/testing/integration-tests)
- [Firebase TestLab](https://firebase.google.com/docs/test-lab?hl=ja)

### Firebase TestLab の Roboテスト をDevinで実行する
- Workload Identity プール を有効にし、プールを作成する
  - AWS で作成を選択
- Devin と GitHub に環境変数を設定する
```sh
$ gcloud iam workload-identity-pools providers describe HOGE_PROVIDER_ID \
  --workload-identity-pool=HOGE_POOL_ID \
  --location=global \
  --format='value(name)'
```
- 出力した値を WIF_PROVIDER に設定する

- GCPのIAMのサービスアカウントで、メールアドレスを確認
  - WIF_SERVICE_ACCOUNT に設定する
    - 下記の権限を付与 (まだ不足しているっぽい？)
      - roles/firebase.testAdmin (TestLab 管理者)
      - Workload Identity プール権限を付与する
      - roles/serviceusage.serviceUsageAdmin (ServiceUsage 管理者)
      - Cloud Storage Object 管理者
- Firebase のプロジェクト設定で、プロジェクトIDを確認する
  - FIREBASE_PROJECT_ID に設定する
- Google Storage のバケットを作成し、BUCKET_NAME に設定する

#### 属性マッピング
- google.subject==assertion.sub
- attribute.repository_owner_id==assertion.repository_owner_id
#### 属性条件
- attribute.repository_owner_id=='https://api.github.com/users/<GitHubのユーザー名>でわかるID'
- アクセスを許可、でサービスアカウントとWorkload Identity プールを紐づける

### Google Play Console

- [Google Play Console](https://play.google.com/console)

```sh
# Android appbundle ビルド
$ flutter build appbundle --release

# ログを詳細に出力するビルド
$ flutter build appbundle --release --verbose
```
- 内部テストリリースでアプリを使えるようにするには、下記の部分を `AndroidProvider.playIntegrity` に変更する必要あり
- `AndroidProvider.debug` ではNG
```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
);
```

- Google Console にリリースした場合は、Google Console の証明書 SHA256 を取得し、FirebaseのAppCheckに貼り付け、google-service.json を更新する必要がある。
  - [Android証明書フィンガープリントを取得](https://dev.adjust.com/ja/sdk/android/integrations/retrieve-certificate-fingerprints/#from-google-play-console)
  - [stack-overflow](https://stackoverflow.com/questions/79715471/i-am-unable-to-test-my-app-in-closed-testing-because-of-app-check-from-firebase?utm_source=chatgpt.com)
    - 問題は、Play ストアに公開するときに、Google が独自の証明書を使用して aab に署名するため、Firebase のプロジェクト設定/App Check で証明書 SHA-256 が無効になることでした。
    - Play Console の整合性タブから SHA-256 を Firebase プロジェクトと App Check に追加した後、クローズド テストでアプリをテストできます。

- [stack-overflow](https://stackoverflow.com/questions/66653074/how-to-fix-apk-is-using-camera-permissions-that-require-a-privacy-policy-error?utm_source=chatgpt.com)
  - Play コンソールで「APK はプライバシー ポリシーを必要とするカメラ権限を使用しています」というエラーを修正するにはどうすればよいでしょうか?
  - アプリの manifest.xml にはデバイスの情報にアクセスする権限がありますが、Play ストアに送信する際にプライバシー ポリシー リンクがありません。そのため、この警告が表示されます。
- [審査のためにアプリを準備する プライバシーポリシー](https://support.google.com/googleplay/android-developer/answer/9859455?hl=ja#:~:text=%E3%82%92%E6%8F%90%E4%BE%9B%E3%81%99%E3%82%8B-,%E3%83%97%E3%83%A9%E3%82%A4%E3%83%90%E3%82%B7%E3%83%BC%20%E3%83%9D%E3%83%AA%E3%82%B7%E3%83%BC,-%E3%82%A2%E3%83%97%E3%83%AA%E3%81%AE%E3%82%B9%E3%83%88%E3%82%A2)
- [Notionで用意したプライバシーポリシー](https://inky-tea-139.notion.site/26829a2fd70e809993c9d51c7abad7a2?pvs=73)

```sh
# デバッグコード採取用のログ収集コマンド
$ adb logcat | grep -i "secret into the allow list in the Firebase Console for your project" 
```

### テスト

```sh
$ flutter test

# カバレッジの算定。coverage/lcov.info が出力される
$ flutter test --coverage
# HTML形式のカバレッジレポートを生成
$ genhtml coverage/lcov.info -o coverage/html
# ブラウザで確認
$ open coverage/html/index.html
```

### Linter

- [flutter_lints 6.0.0](https://pub.dev/packages/flutter_lints)

```sh
# 検出
$ flutter analyze

# 自動修正
$ dart fix --apply
```

### Devin

```sh
# Dependency
$ cd ~/repos/detection_game && cd ~repos/../ && \
    sudo DEBIAN_FRONTEND=noninteractive  apt-get update && sudo \
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confnew" upgrade && \ 
    sudo  apt-get -y install  curl git unzip xz-utils zip libglu1-mesa && \
    rm -rf flutter && git clone https://github.com/flutter/flutter.git -b stable && \
    cd ~/repos/detection_game
$ direnv exec . flutter

# linter
$ direnv exec . flutter analyze

# test
$ direnv exec . flutter test
```

### BGM
- [musmus様](https://musmus.main.jp/music_game.html) ゆっくり急げ！

### 参考サイト
- [Take a picture using the camera](https://docs.flutter.dev/cookbook/plugins/picture-using-came

- [flutter にFirebaseを追加する](https://firebase.google.com/docs/flutter/setup?hl=ja&platform=ios)

- [Firebase Distribution でテスターにアプリ配布](https://firebase.google.com/docs/app-distribution/android/distribute-console?hl=ja&_gl=1*1yfpyy*_up*MQ..*_ga*ODAwMjA1NTQzLjE3NTY5OTI3MTg.*_ga_CW55HF8NVT*czE3NTY5OTI3MTgkbzEkZzAkdDE3NTY5OTI3MTgkajYwJGwwJGgw)

- [Secret Manager で環境変数を管理する](https://firebase.google.com/docs/functions/config-env?hl=ja&gen=2nd)

- [Flutter アプリで App Check を使ってみる](https://firebase.google.com/docs/app-check/flutter/default-providers?hl=ja)

- [Google Play を Firebase にリンクする](https://support.google.com/firebase/answer/6392038)
