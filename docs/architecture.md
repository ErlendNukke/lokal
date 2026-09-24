# Lokal MVP Architecture

## Product

**Lokal** ("home goods") is a mobile-first marketplace connecting local producers with nearby buyers.

Tagline: *From nearby.*

## Goals for MVP

1. Prove producers will list goods
2. Prove buyers will discover nearby products and place orders
3. Keep UX simple enough for gardeners and home bakers

## Stack

| Layer | Choice |
|-------|--------|
| Mobile UI | Flutter (iOS, Android, Web) |
| API | Spring Boot 4.1 / Java 25 |
| DB | PostgreSQL (prod) / H2 in-memory (dev) |
| Migrations | Liquibase |
| Auth | Spring Security + JWT (Google stub ready) |
| Images | S3-compatible (MinIO / R2 / AWS); local filesystem for simple dev |
| Maps | OpenStreetMap + flutter_map |

## High-level flow

```text
Buyer                    API                     Producer
  |                       |                          |
  |-- browse / map ------>|                          |
  |-- open product ------>|                          |
  |-- create order ------>|--- notify (MVP: list) -->|
  |                       |<-- accept / reject ------|
  |<-- status update -----|                          |
  |-- complete + review ->|--- rating update ------->|
```

## Modules

### Backend (`/backend`)
- `domain` — User, ProducerProfile, Product, Order, Review
- `security` — JWT filter + role authorities
- `service` — auth, products, orders, reviews, storage
- `web` — REST controllers under `/api`

### Frontend (`/mobile`)
- Flutter app for iOS, Android, and Web
- Browse (map + feed + categories, fixed 10 km)
- Product detail + order
- Auth (email + Google demo)
- Orders (buyer + producer actions + reviews)
- Producer dashboard (CRUD products + photo upload)
- Profile (role, farm settings)

## Auth model

- Roles: `BUYER`, `PRODUCER`, `BOTH`
- JWT in `Authorization: Bearer …`
- Demo users seeded (password `password123`)

## Location

- Products store lat/lng (Estonia-focused sample around Tallinn/Tartu)
- Fixed 10 km search radius (Haversine in service layer)

## Next scalability steps

1. Real Google / Firebase Auth token verification
2. Push/email notifications on order events
3. Postgres + PostGIS for geo queries
4. Chat between buyer and producer
5. Payments — **not in MVP**: buyers pay producers in person at pickup/delivery (no in-app checkout)

Photo storage: see `docs/storage-s3.md` (`STORAGE_TYPE=s3`).
