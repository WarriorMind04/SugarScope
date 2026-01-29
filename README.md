# SugarScope

Diabetes-focused iOS app: meal scan (Vision + USDA), health logging, reminders, charts, reports, and Apple Watch.

## Features

- **Scan meals**: Camera or photo library → Vision AI + USDA FoodData Central API → nutrition (sugar, carbs, fat, calories, portion).
- **Log health**: Blood glucose, meals, sugar intake, medications.
- **Dashboard**: Daily summary, weekly and monthly charts (glucose, sugar).
- **Smart reminders**: Medication times, blood glucose checks, meal times. Notifications on iPhone and Apple Watch.
- **Medical reports**: Generate PDF reports of your health data; store securely on device; share via Share sheet.
- **Apple Watch**: Quick log glucose, confirm medication / glucose check. Notifications mirrored to Watch.

## Setup

### USDA API key

1. Get a free key: [https://fdc.nal.usda.gov/api-key-signup](https://fdc.nal.usda.gov/api-key-signup)
2. In Xcode: select the **NEW5** target → **Build Settings** → search **USDA_API_KEY** → set your key (or add `USDA_API_KEY` to Info.plist).
3. The project defaults to `DEMO_KEY` (rate-limited) if unset.

### Apple Watch app

1. **File → New → Target** → **Watch App**.
2. Name it e.g. **SugarScope Watch**, finish.
3. Replace the generated Watch app code with the files in **SugarScopeWatch/**:
   - `SugarScopeWatchApp.swift` (Watch `@main`),
   - `WatchContentView.swift` (UI + WatchConnectivity).
4. Add those files to the Watch target’s **Compile Sources**.
5. In the **iOS app target** → **General** → **Frameworks, Libraries, and Embedded Content** → add the Watch app.

Reminders are sent as local notifications; they appear on Watch when the Watch app is installed. Use the Watch app to confirm reminders or quick-log glucose.

## Requirements

- iOS 17+ (SwiftData, Charts)
- Xcode 15+
- Optional: watchOS 10+ for Watch app

## Privacy

Health data is stored only on device (SwiftData). Reports are saved in Application Support and can be shared at your choice.
