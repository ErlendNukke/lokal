# Lokal Flutter app

Native iOS / Android (and Web) client for the Lokal marketplace.

## Run

```bash
flutter pub get

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

# iOS
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:8080

# Android emulator
flutter run -d android
```

Android emulator defaults to `http://10.0.2.2:8080` (host machine loopback).

## Structure

```text
lib/
  main.dart
  theme/           Scandinavian brand theme
  models/          API models
  services/        API, auth, marketplace
  screens/         browse, product, auth, orders, producer, profile
  widgets/         shared UI
```
