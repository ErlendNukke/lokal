# Kodukraam

**Otse tegijalt. Otse koju.**

Mobile-first marketplace MVP connecting Estonian local producers with nearby customers — a blend of farmers market, neighborhood marketplace, and simple ordering.

## What's included

| Area | Status |
|------|--------|
| UX wireframes | `docs/wireframes.md` |
| Architecture | `docs/architecture.md` |
| Database schema | `docs/database.md` + Liquibase |
| Spring Boot REST API | JWT auth, products, orders, reviews, uploads |
| Angular 20 + Ionic frontend | Browse map, product, auth, producer dashboard, orders |
| Sample Estonia data | Tallinn & Tartu producers/products |
| Docker Compose | Postgres + MinIO ready |

## Quick start (dev)

### 1. API (H2 in-memory)

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

API: http://localhost:8080  
Health: http://localhost:8080/actuator/health

### 2. App

```bash
cd frontend
npm install
npm start
# or: ionic serve
```

App: http://localhost:4200

### Demo accounts

Password for all: `password123`

| Email | Role |
|-------|------|
| `anna@kodukraam.ee` | Buyer |
| `mari@kodukraam.ee` | Producer + buyer (Tammemäe Aed) |
| `juri@kodukraam.ee` | Producer (Saare Mesila) |
| `liisa@kodukraam.ee` | Producer (Kase Käsitöö) |

## REST API (MVP)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | — | Email register + role |
| POST | `/api/auth/login` | — | Email login |
| POST | `/api/auth/google` | — | Google login stub |
| GET/PUT | `/api/auth/me` | ✓ | Profile |
| GET | `/api/products` | — | Search nearby (`lat`, `lng`, `radiusKm`, `category`, `q`) |
| GET | `/api/products/{id}` | — | Product detail |
| GET/POST/PUT/DELETE | `/api/producer/products` | ✓ | Producer listings |
| POST | `/api/uploads` | ✓ | Image upload |
| POST | `/api/orders` | ✓ | Place order |
| GET | `/api/orders/mine` | ✓ | Buyer orders |
| GET | `/api/producer/orders` | ✓ | Producer inbox |
| PATCH | `/api/orders/{id}/status` | ✓ | Accept / reject / complete / cancel |
| POST | `/api/reviews` | ✓ | Rate after completed order |
| GET | `/api/producers/{id}/reviews` | — | Producer reviews |

## Product categories

- FOOD — vegetables, berries, bread, cakes
- PLANTS — seedlings, houseplants
- FARM — honey, eggs, jars
- HANDMADE — crafts
- OTHER

## Design

Scandinavian, warm, trustworthy:

- Forest green `#2F5D50`
- Beige `#F3EBE0`
- Cream background, white surfaces
- Dark gray text
- Fonts: Fraunces (brand) + Source Sans 3 (UI)
- Maps: OpenStreetMap + Leaflet

## Production profile

```bash
docker compose up -d db
cd backend
SPRING_PROFILES_ACTIVE=prod \
DATABASE_URL=jdbc:postgresql://localhost:5432/kodukraam \
DATABASE_USER=kodukraam \
DATABASE_PASSWORD=kodukraam \
mvn spring-boot:run
```

## Project layout

```text
backend/     Spring Boot 3 + Java 21 + Liquibase
frontend/    Angular 20 + Ionic 8 + Leaflet + Angular Material
docs/        Wireframes, architecture, schema
docker-compose.yml
```

## MVP success metric

Not perfection — usage: Estonian producers list goods, nearby buyers order them.
