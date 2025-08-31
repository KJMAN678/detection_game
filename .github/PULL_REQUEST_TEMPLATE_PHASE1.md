# フェーズ1: ローカルPoC（Emulator Suite + C案）対応

- 関連Issue: #10
- スコープ: Firebase Local Emulator Suite 利用 + クライアント直Vision（C案）
- 注意: MLの信頼度スコアは表示・使用しない。秘密情報はコミットしない

## 変更点
- ClientDirectVisionAdapter を追加（Vision REST API 直呼び）
- main.dart の「解析する」フローを C案に差し替え
- モデル/UI は A案と同一スキーマ（BBox正規化、ラベル名のみ表示）
- 依存追加: http

## 使い方（ローカルPoC）
```
flutter run --dart-define=VISION_API_KEY=XXXXX
```

## 確認観点
- 撮影→解析→バウンディングボックス/ラベル名のみ表示
- エラー表示（キー未設定、ネットワーク、Quota等）
- スキーマ互換（後続A案に切替してもUI変更不要）
