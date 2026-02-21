# AI Expense Scanner

AI Expense Scanner is a Flutter app for tracking personal expenses with receipt OCR, voice input, monthly analytics, and local-first storage.

## Features

- Scan receipts using camera or gallery image import.
- Auto-extract amount, merchant, date, and category using on-device OCR (Google ML Kit).
- Review and edit detected fields before saving.
- Add expenses manually when no bill image is available.
- Use voice assistant to add expenses by speech (example: "I paid 250 in gpay for recharge").
- Use voice assistant to query spending summaries by period/category.
- View a dashboard with today total, today transaction count, and current month total.
- View a 7-day spending trend line chart.
- View category distribution analytics.
- Open monthly overview with month-wise totals and category summary.
- Manage saved expenses with edit/delete actions in the monthly expense list.
- Budget alerts at 80% and 100% usage (local notifications).
- Export current month data to CSV or JSON.
- Backup SQLite database file for sharing/storage.
- Local-only data persistence using SQLite (`sqflite`).

## Tech Stack

- Flutter + Dart
- `camera` for receipt capture
- `google_mlkit_text_recognition` for OCR
- `sqflite` for local database
- `fl_chart` for analytics charts
- `speech_to_text` + `flutter_tts` for voice assistant
- `flutter_local_notifications` for budget notifications
- `share_plus` for export/backup sharing

## Project Structure

```text
lib/
  app.dart
  main.dart
  routes/
  core/
    constants/
    services/
    theme/
    ui/
  data/
    database/
    models/
    repositories/
  features/
    dashboard/
    monthly/
    scan/
    settings/
    shell/
    voice_assistant/
```

## Getting Started

### Prerequisites

- Flutter SDK (Dart SDK included)
- Android Studio or VS Code with Flutter plugins
- Android/iOS emulator or physical device

### Run Locally

```bash
flutter pub get
flutter run
```

### Run Tests

```bash
flutter test
```

## Permissions Used

### Android

- `CAMERA`
- `RECORD_AUDIO`
- `POST_NOTIFICATIONS`
- `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` (legacy support)

### iOS

- `NSCameraUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Data Model (Expense)

Each expense record stores:

- amount
- merchant
- category
- payment mode
- created date-time
- optional receipt image path
- optional raw OCR text

## Notes

- App is local-first; no cloud sync or account auth is currently implemented.
- OCR and voice parsing are heuristic-based and optimized for common Indian receipt/payment wording (`en_IN` locale).
- Settings screens for budget and export/backup are implemented via routes and services.
