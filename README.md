# Vocablet

一款優雅的英文單字學習 App，靈感來自 iPhone Notes 的簡約設計。

## 功能

- **資料夾分類** — 將單字依情境整理進自訂資料夾（圖示 + 顏色）
- **標籤搜尋** — 為單字加上標籤，快速跨資料夾查找
- **字卡測驗** — 翻轉式字卡 + 滑動評分，追蹤熟悉度
- **多選題測驗** — 4 選 1 測驗，計算分數並列出錯誤單字
- **發音功能** — 點擊即可聆聽英語原音（AVSpeechSynthesizer）
- **iCloud 同步** — 使用 NSPersistentCloudKitContainer，跨裝置自動同步
- **複習推播** — 每日定時提醒，可自訂時間

## 設計風格

百合白色系 × 薄荷綠 × 圓角設計，簡約舒適。

## 技術棧

| 層次 | 技術 |
|------|------|
| UI | SwiftUI |
| 資料持久化 | Core Data |
| 雲端同步 | CloudKit (NSPersistentCloudKitContainer) |
| 發音 | AVFoundation / AVSpeechSynthesizer |
| 推播 | UserNotifications (本地推播) |

## 開始使用

1. 用 Xcode 15+ 開啟 `Vocablet.xcodeproj`
2. 在 **Signing & Capabilities** 設定你的 Team 與 Bundle ID
3. 啟用 **iCloud** capability 並新增 CloudKit container：`iCloud.com.vocablet.app`
4. 建置並執行於 iOS 17.0+ 裝置或模擬器

## 資料模型

```
CDFolder          CDWord              CDTag
├── id            ├── id              ├── id
├── name          ├── term            ├── name
├── icon          ├── definition      └── words (↔ CDWord)
├── colorHex      ├── pronunciation
├── createdAt     ├── examples
└── words →       ├── notes
                  ├── isFavorite
                  ├── masteryLevel (0–4)
                  ├── reviewCount
                  ├── createdAt
                  ├── lastReviewed
                  ├── folder → CDFolder
                  └── tags ↔ CDTag
```

## 需求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- iCloud 帳號（同步功能需要）
