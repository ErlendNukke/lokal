# Lokal

**From nearby.**

Mobile-first marketplace MVP connecting local producers with nearby customers.

## Stack

| Layer | Tech |
|-------|------|
| Mobile app | **Flutter** (iOS, Android, Web) |
| API | Spring Boot 4.1 / Java 25 |
| DB | PostgreSQL (prod) / H2 (dev) |
| Auth | JWT (+ Google demo stub) |
| Maps | OpenStreetMap + `flutter_map` |

## Quick start

### 1. API

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

API: http://localhost:8080

### 2. Flutter app

```bash
cd mobile
flutter pub get

# Chrome / web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

# iOS simulator
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:8080

# Android emulator (default API host is 10.0.2.2:8080)
flutter run -d android
```

### Demo accounts

Password: `password123`

| Email | Role |
|-------|------|
| `anna@lokal.app` | Buyer |
| `mari@lokal.app` | Producer + buyer |
| `juri@lokal.app` | Producer |

## App features

- Browse nearby products on an Estonia-focused OSM map
- Category filters within a fixed 10 km radius
- Product detail + order (pickup/delivery + message)
- Producer dashboard (list products, upload photos)
- Order accept / reject / complete + reviews
- Email login, register with role, Google demo login

## Docs

- `docs/wireframes.md`
- `docs/architecture.md`
- `docs/database.md`
- `docs/api-smoke.md`

## Project layout

```text
backend/   Spring Boot API
mobile/    Flutter app (iOS / Android / Web)
docs/      UX + architecture
```
