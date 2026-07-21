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
| API | Spring Boot 3.4 / Java 21 |
| DB | PostgreSQL (prod) / H2 in-memory (dev) |
| Migrations | Liquibase |
| Auth | Spring Security + JWT (Google stub ready) |
| Images | Local uploads now; S3/MinIO-compatible interface next |
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
- Browse (map + feed + categories + radius)
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
- Radius filters: 5 / 20 / 50 km (Haversine in service layer)

## Next scalability steps

1. Real Google / Firebase Auth token verification
2. MinIO/S3 image storage
3. Push/email notifications on order events
4. Postgres + PostGIS for geo queries
5. Chat between buyer and producer
6. Payments (optional; keep cash/pickup first)
