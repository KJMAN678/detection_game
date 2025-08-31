# フェーズ1: ローカルPoC（Emulator Suite + C案）実装

関連: #10 / 参考: #8

## 概要
- クライアントから直接 Google Cloud Vision API を呼び出す PoC 実装（C案）
- UI はラベル名のみ表示（MLスコアは不使用）
- レスポンススキーマは後続A案と互換（BBoxは0-1正規化）

## 変更内容
- ClientDirectVisionAdapter 追加（Vision REST API 直呼び）
- DisplayPictureScreen の「解析する」処理を C案に切替
- 依存追加: http

## 実行方法（ローカルPoC）
```
flutter pub get
flutter run --dart-define=VISION_API_KEY=YOUR_API_KEY
```

## 注意
- キーはリポジトリにコミットしない（.env.example 参照）
- 本PRはPoC用途。後続で A案（Storage→Functions→Vision）に移行予定

Link to Devin run: https://app.devin.ai/sessions/7ed6f72b583b4efab49b795b846ef5a6
依頼者: koji / @KJMAN678
