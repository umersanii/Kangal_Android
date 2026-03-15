# Kangal

Kangal is a local-first personal finance Android app built with Flutter. It ingests HBL SMS and NayaPay email transactions, stores them in a local Drift (SQLite) database, and optionally syncs with Supabase.

## Requirements

- Flutter SDK: `>=3.24.0` (stable channel recommended)
- Dart SDK: bundled with Flutter
- Android SDK (API 26+)

## Setup

From the `kangal/` directory:

- Install dependencies: `flutter pub get`
- Regenerate code (Drift/Freezed/JSON): `dart run build_runner build --delete-conflicting-outputs`

## Run

- Start app: `flutter run`
- Analyze: `flutter analyze`
- Run tests: `flutter test`

## Architecture

Kangal follows MVVM with `provider` and repository abstractions.

```text
UI Screens/Widgets
	|
	v
ChangeNotifier ViewModels
	|
	v
Repository Interfaces
	|
	v
Drift Repository Implementations
	|
	v
DAOs (Drift)
	|
	v
SQLite (local source of truth)

Optional cloud path:
SQLite <-> Sync Repository <-> Supabase
```

## APK Build

- Release APK: `flutter build apk --release`
