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
### Firebase + Cloud Vision 連携手順（概要）

1) Firebase/GCP 準備（コンソール）
- Firebase プロジェクトを新規作成（例: detection-game-dev）
- リージョン選定（例: asia-northeast1）
- 課金有効化
- 有効化: Cloud Vision API, Firebase Storage, Cloud Functions(2nd gen)

2) Android アプリ登録
- パッケージ名: com.example.detection_game（変更する場合は一致させる）
- google-services.json を Firebase Console から取得し android/app/ に配置（コミットしない）
- FlutterFire CLI 実行: flutterfire configure

3) 依存関係
- pubspec.yaml に firebase_core / firebase_storage / cloud_functions を追加
- flutter pub get

4) Cloud Functions（Callable）
- functions/ ディレクトリで Node.js/TypeScript を使用
- analyzeImage Callable を実装し、Storage の gs:// パスを受け取り、Vision API で Object Localization + Label Detection を実施して JSON を返却

5) アプリ動作
- カメラで撮影 → Storage にアップロード → Callable analyzeImage 呼び出し → 結果を UI 表示（BBox/ラベル/スコア）

注意: 秘密情報（google-services.json 等）はコミットしない
### スコアリング方針
- ラベル推定で返る「機械学習の信頼度スコア」は使用しません
- 事前定義の「ラベル名 → 点数」テーブルを用いてゲームスコアを計算します（テーブルは後日決定）
- 現状はプレースホルダ実装（例: person/dog/cat に仮の点数）。最終テーブル確定後に差し替えます

### アーキテクチャ代替案（A以外）
B) Cloud Run（HTTP API）
- フロー: 端末 → Cloud Run API → Vision API → 結果返却
- 長所: ランタイム/パッケージ自由度、オートスケール、複雑な前後処理をまとめやすい
- 短所: 認証/認可・運用・コスト設計が増える。Firebase連携が薄くなる
- 向き: 既にGCPマイクロサービスやAPIゲートウェイがある場合

C) クライアントから直接Vision API
- フロー: 端末 → Vision API 直呼び
- 長所: 実装最小
- 短所: API鍵露出リスク/不正利用・課金リスクが大きい。モバイル配布に不向き
- 結論: 非推奨（PoC以外は避ける）
